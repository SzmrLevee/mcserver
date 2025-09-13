# 📘 Minecraft Docker Setup – Teljes, soronkénti magyarázat

Ez a dokumentum **egy helyen** magyarázza el a repóban és a fő README-ben szereplő **összes kódot és parancsot**, soronként.
Az alábbi fájlokra vonatkozik:
- `Dockerfile`
- `entrypoint.sh`
- `defaults/server.properties`
- README parancsblokkjai (Gyors indítás, Friss futtatás, Online/Offline, Mentés/Visszaállítás, stb.)

> Tipp: ez a magyarázat önállóan is használható – nem kell közben a forrásfájlokat nyitogatni.

---

## 🧱 Dockerfile – rétegenként

```
FROM ubuntu:24.04
```
- A konténer **alap image**-e. Stabil, hosszú támogatású Ubuntu, amire építjük a Minecraft szervert.

```
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-21-jre-headless curl jq ca-certificates && rm -rf /var/lib/apt/lists/*
```
- Csomaglista frissítés, majd a **minimális** szükséges csomagok telepítése:
  - `openjdk-21-jre-headless` – Java futtatókörnyezet (fej nélküli, nincs GUI).
  - `curl` – letöltéshez.
  - `jq` – JSON feldolgozás (a Mojang manifestből olvassuk ki a legfrissebb verzió linkjeit).
  - `ca-certificates` – HTTPS-tanúsítványok (biztonságos letöltés).
- A végén takarítás (`/var/lib/apt/lists/*`), hogy az image **kisebb** legyen.

```
WORKDIR /mc
```
- Munkakönyvtár beállítása. Innentől minden relatív elérési út a `/mc`-hez viszonyít.

```
# Legfrissebb Mojang server.jar letöltése manifestből
RUN set -eux; \
  curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json -o /tmp/manifest.json; \
  LATEST_ID="$(jq -r '.latest.release' /tmp/manifest.json)"; \
  VERSION_URL="$(jq -r --arg v "$LATEST_ID" '.versions[] | select(.id==$v) | .url' /tmp/manifest.json)"; \
  curl -fsSL "$VERSION_URL" -o /tmp/version.json; \
  curl -fsSL "$(jq -r '.downloads.server.url' /tmp/version.json)" -o /mc/server.jar; \
  rm -f /tmp/manifest.json /tmp/version.json
```
- `set -eux` – hibánál álljon le (`-e`), írja ki a futó parancsokat (`-x`), és a pipeline-okban is legyen szigorú (`-u`).
- Letölti a Mojang **verzió manifestet** → kiolvassa a **legfrissebb stabil** (`latest.release`) verziót → ahhoz letölti a **verzió JSON-t** → abból **kiveszi a szerver JAR** URL-jét és letölti `/mc/server.jar` néven. Ideiglenes fájlokat törli.

```
RUN echo "eula=true" > /mc/eula.txt
```
- A Minecraft EULA elfogadása. Enélkül a szerver **azonnal kilépne**.

```
COPY defaults/ /defaults/
```
- A repóban lévő **alap fájlokat** (pl. `server.properties`, ikon) bemásolja az image-be. Ezeket az `entrypoint.sh` fogja **seedelni** az első indításkor.

```
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
```
- A belépési pont script bemásolása és futtathatóvá tétele.

```
ENV JAVA_OPTS="-Xms1G -Xmx2G"
```
- **Alap memória** (heap) beállítás: induláskor 1 GB, maximum 2 GB. Futtatáskor felülírható `-e JAVA_OPTS="..."`-szal.

```
EXPOSE 25565
```
- Dokumentálja, hogy a konténer a **25565/TCP** porton hallgat (a külső elérhetőséghez a `-p 25565:25565` kell).

```
CMD ["/entrypoint.sh"]
```
- A konténer indulásakor ezt a parancsot futtatja: **seeding + szerver indítás**.

---

## 🚪 entrypoint.sh – seeding + indulás

```
set -e

if [ ! -f "/mc/server.properties" ]; then
  cp -n /defaults/* /mc/
fi

exec java ${JAVA_OPTS:- -Xms1G -Xmx2G} -jar /mc/server.jar nogui
```
- `set -e` – ha bármelyik parancs hibát ad, **álljon le** a script. Így nem marad félig kész állapotban.
- `if [ ! -f "/mc/server.properties" ]` – csak akkor seedel, ha még **nincs** `server.properties` a `/mc` gyökérben.
- `cp -n /defaults/* /mc/` – átmásolja az alapfájlokat. `-n` = **no clobber** → nem ír felül meglévőt.
- `exec java ${JAVA_OPTS:- -Xms1G -Xmx2G} -jar /mc/server.jar nogui` – a shell folyamat helyére lép a **Java szerver** (szebb leállítás, jelkezelés). Ha nincs `JAVA_OPTS`, a default 1–2 GB.

> Miért a `/mc` gyökérbe seedelünk és nem `/mc/world`-be? Mert a Minecraft **a `server.properties`-t a working dir-ben** keresi, míg a világ adatokat a `level-name` alapján létrehozza (nálad `world`). A világot mountoljuk, a szerverfájlok a konténerben maradnak.

---

## ⚙️ defaults/server.properties – mezők magyarázata

```
motd=§cK §6é §en §ay §bs §dz §ce §6r §ek §6e §er §ce §6s §ek §6e §ed §6ő §ck\n§cA§6k§en§aá§bz§6d §ck§6i §ea §af§ba§cl§du§ds§ei§aa§ck§6a§et§c!
```
- A szerverlistában megjelenő **név/leírás**. A `§` kódok színeznek, a `\\n` **új sor**.

```
server-port=25565
```
- A **belső** port (a konténeren belül), amin a szerver hallgat.

```
online-mode=true
```
- Mojang/Microsoft **hitelesítés bekapcsolva**. Ha TLauncher/offline klienst használsz, ezt `false`-ra kell állítani.

```
enforce-secure-profile=true
```
- A biztonságos profilkövetelmény. Offline/TLauncher esetén **állítsd `false`-ra**, különben „Failed to verify username!”.

```
level-name=world
```
- A világ mappa neve. A hoston ez lesz a **mountolt** `~/mc-data/world`.

```
view-distance=10
simulation-distance=10
```
- Látótávolság és **szimuláció**s távolság chunkokban. Nagyobb érték → több CPU/RAM.

```
enable-command-block=true
```
- Engedélyezi a **parancsblokkokat** (mini-játékoknál fontos).

```
spawn-protection=10
```
- A spawn körüli **védett zóna** sugara blokkban; itt nem építhetnek a nem-OP játékosok.

```
level-seed=888880777356331877
```
- A világ **seedje** (ugyanazzal a seeddel ugyanaz a térkép generálódik). Ha seedet váltasz, töröld a régi `world` tartalmát és indítsd újra.

---

## 🟢 Gyors indítás – parancsblokkok magyarázata

### Mac / Linux
```bash
docker rm -f mc 2>/dev/null || true
```
- Törli a régi `mc` konténert, a hibát elnyeli (ha nincs ilyen konténer).

```bash
docker build -t mc-server:latest .
```
- Image építés `mc-server:latest` taget adva.

```bash
mkdir -p ~/mc-data/world
```
- A **világ** host mappáját létrehozza (perzisztens adat).

```bash
docker run -d --name mc -p 25565:25565 -v ~/mc-data/world:/mc/world mc-server:latest
```
- Háttérben elindítja a konténert, kiteszi a portot, és csak a `world`-öt mountolja.

```bash
docker logs -f mc
```
- Indítási log követése (hibakereséshez is).

### Windows – PowerShell
```powershell
docker rm -f mc 2>$null
```
- Ugyanaz, mint Linuxon, a hibakimenet eldobása PowerShell módon.

```powershell
docker build -t mc-server:latest .
mkdir -Force C:\Users\<Név>\mc-data\world
docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
docker logs -f mc
```
- `-Force` – létrehozza a mappát, ha még nincs.

### Windows – CMD
```cmd
docker rm -f mc >nul 2>&1
docker build -t mc-server:latest .
mkdir C:\Users\<Név>\mc-data\world
docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
docker logs -f mc
```
- `>nul 2>&1` – stdout és stderr **elnyelve** (mint Linuxon a `/dev/null`).

---

## ♻️ Friss futtatás új build után (miért jó?)

```bash
docker stop mc && docker rm mc && docker run -d --name mc -p 25565:25565 -v ~/mc-data/world:/mc/world mc-server:latest
```
- **Megállítja** a szervert → törli a konténert → **friss image-ből** újraindít ugyanazzal a `world`-del.  
- Hasznos: új Dockerfile, új Minecraft verzió, config/motd változás, stb.

PowerShell/CMD megfelelői a README-ben szerepelnek; a logika ugyanaz.

---

## 🔐 Online vs. Offline váltás (konténerben)

### Offline módra
```bash
docker exec mc sh -lc "sed -i 's/^online-mode=.*/online-mode=false/' /mc/server.properties || echo 'online-mode=false' >> /mc/server.properties"
docker exec mc sh -lc "sed -i 's/^enforce-secure-profile=.*/enforce-secure-profile=false/' /mc/server.properties || echo 'enforce-secure-profile=false' >> /mc/server.properties"
docker restart mc
```
- `docker exec` – parancs fut a **futó** konténerben.
- `sed -i` – a fájlon **helyben** cseréli az adott kulcsot; ha nincs sor, `echo >>` hozzáadja.
- `docker restart` – azonnal érvényesülnek a beállítások.

### Online módra vissza
```bash
docker exec mc sh -lc "sed -i 's/^online-mode=.*/online-mode=true/' /mc/server.properties || echo 'online-mode=true' >> /mc/server.properties"
docker restart mc
```
- Visszakapcsolja a Mojang hitelesítést. `enforce-secure-profile` maradhat `false`, de online üzemnél ajánlott `true`.

---

## 🧰 OP (admin) jog adása

### A) Szerver konzolból (ajánlott)
```bash
docker attach mc
# a konzolban:
op <játékosnév>
# kilépés: Ctrl+P, Ctrl+Q
```
- A `docker attach` rácsatlakozik a **futó** szerverfolyamat STDIN-jára/STDOUT-jára.  
- Az `op <név>` kiadása után **ne Ctrl+C-vel** lépj ki (az leállít), hanem `Ctrl+P`, majd `Ctrl+Q` (detach).

### B) Kézzel az `ops.json`-ba
```bash
docker stop mc
# szerkeszd: ~/mc-data/world/ops.json
# példa:
# [
#   { "uuid": "00000000-0000-0000-0000-000000000000", "name": "mrszmr", "level": 4, "bypassesPlayerLimit": false }
# ]
docker start mc
```
- Offline módban a UUID nem valós, ezért jobb a módszer A). Online módban a Mojang-féle **valódi UUID** kell.

---

## 💾 Biztonsági mentés + visszaállítás

### Mentés
```bash
mkdir -p ~/mc-backup && docker stop mc && cp -r ~/mc-data/world ~/mc-backup/world-$(date +%Y%m%d) && docker start mc
```
- Létrehoz egy **dátumozott** másolatot a világodról. Leállítás → másolás → indulás.

### Visszaállítás röviden
```bash
docker stop mc
mv ~/mc-data/world ~/mc-data/world-old-$(date +%Y%m%d)
cp -r ~/mc-backup/world-YYYYMMDD ~/mc-data/world
docker start mc
```
- A korábbi mentést használod **új élő világként**.

> A teljes, részletes RESTORE rész a fő README végén és külön dokumentumban is megtalálható.

---

## 🌱 Új világ (új seed)

1) Állíts **új** `level-seed`-et a `server.properties`-ben.  
2) Töröld a **world mappa tartalmát** (ne magát a mappát!).  
3) `docker restart mc` → a szerver **új világot** generál.

---

## 🌍 Internetre tétel

1) Routerben **25565/TCP** port forward a host gépedre.  
2) Tűzfal engedély:
   - macOS/Linux: `sudo ufw allow 25565/tcp`
   - Windows: `netsh advfirewall firewall add rule name="Minecraft" dir=in action=allow protocol=TCP localport=25565`
3) Domain: A rekord a publikus IP-re. Dinamikus IP esetén DynDNS.  
4) **Offline módot ne tedd ki internetre!**

---

## ❗ Hibakeresés, tippek

- A konténer **azonnal kilép**? Ne mountold a teljes `/mc`-t; csak `-v ~/mc-data/world:/mc/world`!  
- „**Failed to verify username!**” – offline-hoz `online-mode=false` + `enforce-secure-profile=false`.  
- `nano` hiányzik a konténerben? **Hoston** szerkeszd a fájlokat a mountolt mappában.  
- Az MOTD („A Minecraft Server”) a `server.properties` `motd` kulcsa.  
- Több RAM kell? Futtatásnál: `-e JAVA_OPTS="-Xms2G -Xmx6G"`.

---

## ✅ Lényeg egy mondatban
**A világ (world) legyen mountolva, minden más maradjon a konténerben; első indításkor seedeljünk `defaults/`-ból; online/offline módot és OP jogot parancsokkal állítsuk.**

Jó játékot! 🎮