# ⛏️ Minecraft Server Docker Setup (teljes)

Ez a dokumentáció lépésről lépésre bemutatja, hogyan futtass **vanilla Minecraft Java** szervert Dockerrel **Mac**, **Linux** vagy **Windows** rendszeren.  
Az itt leírt megoldás a repó **defaults/** mappájából **automatikusan seedeli** az első indításkor a `server.properties`-t a mounted `world` mappába.

---

## 📁 Repo felépítése

```
├─ defaults/
│ ├─ server.properties # előre beállított properties (innen seedeljük első indításkor)
│ └─ server-icon.png # alapértelmezett szerver ikon
├─ Dockerfile # image build: Java + friss server.jar letöltése
├─ entrypoint.sh # belépési pont: seedelés (properties + ikon) és a szerver indítása
├─ icon.png # alapértelmezett ikon (ha nincs defaults/server-icon.png)
└─ README.md # dokumentáció
```

---

## 🚀 Gyors indítás – Mac / Linux (world-only mount)
```bash
docker rm -f mc 2>/dev/null || true
docker build -t mc-server:latest .
mkdir -p ~/mc-data/world
docker run -d --name mc -p 25565:25565 -v ~/mc-data/world:/mc/world mc-server:latest
docker logs -f mc
```

---

## 🚀 Gyors indítás – Windows (PowerShell, world-only mount)
```powershell
docker rm -f mc 2>$null
docker build -t mc-server:latest .
mkdir -Force C:\Users\<Név>\mc-data\world
docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
docker logs -f mc
```

---

## 🚀 Gyors indítás – Windows (CMD, world-only mount)
```cmd
docker rm -f mc >nul 2>&1
docker build -t mc-server:latest .
mkdir C:\Users\<Név>\mc-data\world
docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
docker logs -f mc
```

---

## 1️⃣ Hosts fájl (nem kötelező, de kényelmes)

**Mac / Linux**
```bash
sudo nano /etc/hosts
```
Adj hozzá egy sort:  
```
127.0.0.1 vm1.test
```

**Windows**
Jegyzettömb rendszergazdaként, fájl:  
```
C:\Windows\System32\drivers\etc\hosts
```
Adj hozzá egy sort:  
```
127.0.0.1 vm1.test
```

Ezután a kliensben a cím lehet: `vm1.test:25565`

---

## 2️⃣ Image build

**Mac / Linux / Windows (PowerShell/CMD)**
```bash
docker build -t mc-server:latest .
```

---

## 3️⃣ Szerver indítása (world-only mount)

A **világ** adatai a hostodon:  
- Mac/Linux → `~/mc-data/world`  
- Windows → `C:\Users\<Név>\mc-data\world`

**Mac / Linux**
```bash
mkdir -p ~/mc-data/world && docker run -d --name mc -p 25565:25565 -v ~/mc-data/world:/mc/world mc-server:latest
```

**Windows (PowerShell)**
```powershell
mkdir C:\Users\<Név>\mc-data\world; docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
```

**Windows (CMD)**
```cmd
mkdir C:\Users\<Név>\mc-data\world && docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
```

---

## 4️⃣ Logok

```bash
docker logs -f mc
```

---

## 5️⃣ Konténer státusz

Futók:
```bash
docker ps
```
Részletes:
```bash
docker inspect mc
```

---

## 6️⃣ Vezérlés

Leállítás:
```bash
docker stop mc
```
Indítás:
```bash
docker start mc
```
Újraindítás:
```bash
docker restart mc
```

---

## 7️⃣ Friss futtatás új build után

**Mac / Linux**
```bash
docker stop mc && docker rm mc && docker run -d --name mc -p 25565:25565 -v ~/mc-data/world:/mc/world mc-server:latest
```

**Windows (PowerShell)**
```powershell
docker stop mc; docker rm mc; docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
```

**Windows (CMD)**
```cmd
docker stop mc && docker rm mc && docker run -d --name mc -p 25565:25565 -v C:\Users\<Név>\mc-data\world:/mc/world mc-server:latest
```

---

## 8️⃣ Csatlakozás

Ugyanazon a gépen: `localhost:25565` vagy `127.0.0.1:25565`  
LAN: `<host IP>:25565`  (Mac: `ifconfig | grep inet`, Windows: `ipconfig`)  
Hosts névvel: `vm1.test:25565`  
Internet: `<publikus IP>:25565` (router port forward + tűzfal nyitás kell)

---

## 🔐 Online vs. Offline mód (TLauncher)

- **Online (ajánlott internetre):**  
  `online-mode=true` (alapértelmezett a Mojangnál) → **hivatalos Java Edition accounttal** lehet belépni.

- **Offline (TLauncher, csak LAN/privát):**  
  `online-mode=false` és `enforce-secure-profile=false` → nincs Mojang hitelesítés.

### Gyors parancs Dockerben (ha közvetlenül a konténerben akarod állítani)
```bash
# offline módra
docker exec mc sh -lc "sed -i 's/^online-mode=.*/online-mode=false/' /mc/server.properties || echo 'online-mode=false' >> /mc/server.properties"
docker exec mc sh -lc "sed -i 's/^enforce-secure-profile=.*/enforce-secure-profile=false/' /mc/server.properties || echo 'enforce-secure-profile=false' >> /mc/server.properties"
docker restart mc

# online módra vissza
docker exec mc sh -lc "sed -i 's/^online-mode=.*/online-mode=true/' /mc/server.properties || echo 'online-mode=true' >> /mc/server.properties"
docker restart mc
```

---

## 🧰 OP (admin) jog adása – két módszer

### A) Konzolból (ajánlott, a szerver írja be helyesen az UUID-ot)
1) Csatlakozz a szerver konzolhoz:
```bash
docker attach mc
```
2) Írd be a konzolba:
```
op <játékosnév>
```
3) Kilépés úgy, hogy a szerver futva maradjon: **Ctrl+P, majd Ctrl+Q**

### B) Kézzel az `ops.json`-ba (ha nem akarsz attach-olni)
1) Állítsd le ideiglenyen:
```bash
docker stop mc
```
2) Szerkeszd a hoston a `~/mc-data/world/ops.json`-t (ha nincs, hozd létre). Példa offline módhoz:
```json
[
  { "uuid": "00000000-0000-0000-0000-000000000000", "name": "mrszmr", "level": 4, "bypassesPlayerLimit": false }
]
```
3) Indítsd újra:
```bash
docker start mc
```

> Online módban a **valódi** Mojang/Microsoft UUID kell; offline módban a szerver „offline UUID”-ot számol a névből → ezért a **konzolos `op` biztosabb**.

---

## 💾 Biztonsági mentés

**Mac / Linux**
```bash
mkdir -p ~/mc-backup && docker stop mc && cp -r ~/mc-data/world ~/mc-backup/world-$(date +%Y%m%d) && docker start mc
```

**Windows (PowerShell)**
```powershell
mkdir C:\Users\<Név>\mc-backup; docker stop mc; Copy-Item -Recurse C:\Users\<Név>\mc-data\world C:\Users\<Név>\mc-backup\world-$(Get-Date -Format yyyyMMdd); docker start mc
```

**Windows (CMD)**
```cmd
mkdir C:\Users\<Név>\mc-backup && docker stop mc && xcopy /E /I /Y C:\Users\<Név>\mc-data\world C:\Users\<Név>\mc-backup\world-%date:~0,4%%date:~5,2%%date:~8,2% && docker start mc
```

Visszaállítás: állítsd le → nevezd át a jelenlegi `world`-öt → másold vissza a mentést → indítsd.

---

# 💾 Minecraft világ visszaállítása (restore guide)

Ez a leírás bemutatja, hogyan töltsd vissza egy korábbi biztonsági mentésből a Minecraft világodat.

---

## 📂 Hol vannak a fájlok?

- **Élő világ (játék közbeni adatok):**
  - Mac/Linux → `~/mc-data/world`
  - Windows → `C:\Users\<Név>\mc-data\world`

- **Biztonsági mentések (archív):**
  - Mac/Linux → `~/mc-backup/`
  - Windows → `C:\Users\<Név>\mc-backup\`

Mentés neve pl.:  
```
world-20250912
```

---

## 🔄 Visszaállítás lépései

### 1) Szerver leállítása
```bash
docker stop mc
```

### 2) Jelenlegi világ átnevezése (ha meg akarod tartani)
**Mac/Linux**
```bash
mv ~/mc-data/world ~/mc-data/world-old-$(date +%Y%m%d)
```

**Windows (PowerShell)**
```powershell
Rename-Item -Path C:\Users\<Név>\mc-data\world -NewName ("world-old-" + (Get-Date -Format yyyyMMdd))
```

**Windows (CMD)**
```cmd
ren C:\Users\<Név>\mc-data\world world-old-%date:~0,4%%date:~5,2%%date:~8,2%
```

### 3) Másold vissza a mentést
**Mac/Linux**
```bash
cp -r ~/mc-backup/world-YYYYMMDD ~/mc-data/world
```

**Windows (PowerShell)**
```powershell
Copy-Item -Recurse C:\Users\<Név>\mc-backup\world-YYYYMMDD C:\Users\<Név>\mc-data\world
```

**Windows (CMD)**
```cmd
xcopy /E /I /Y C:\Users\<Név>\mc-backup\world-YYYYMMDD C:\Users\<Név>\mc-data\world
```

### 4) Szerver újraindítása
```bash
docker start mc
```

---

## ✅ Összefoglalás
1. Állítsd le a konténert.  
2. Nevezd át vagy töröld a jelenlegi `world` mappát.  
3. Másold vissza a kívánt backupot a `world` mappába.  
4. Indítsd újra a szervert.  

Most már a régi világodból folytathatod a játékot! 🎮

---

## 🌱 Új világ generálása

1) A hoston nyisd meg a `~/mc-data/world/server.properties`-t és állítsd a `level-seed`-et.  
2) Töröld a régi világ tartalmát (csak a **world** mappa belsejét!):
   - Mac/Linux:
     ```bash
     rm -rf ~/mc-data/world/*
     ```
   - Windows (PowerShell):
     ```powershell
     Remove-Item -Recurse -Force C:\Users\<Név>\mc-data\world\*
     ```
   - Windows (CMD):
     ```cmd
     del /S /Q C:\Users\<Név>\mc-data\world\*
     ```
3) Indítsd újra: `docker restart mc`

---

## 🌍 Internetre tétel (opcionális)

1) Router port forward: **25565/TCP** a géped belső IP-jére.  
2) Tűzfal:  
   - Mac/Linux: `sudo ufw allow 25565/tcp`  
   - Windows: `netsh advfirewall firewall add rule name="Minecraft" dir=in action=allow protocol=TCP localport=25565`  
3) Domain → A rekord a publikus IP-re.  
4) Dinamikus IP esetén DynDNS (No-IP, DuckDNS).  
5) **Offline módot ne tedd ki internetre!**

---

## ❗️Hibakeresés (gyors)

- **Konténer azonnal kilép**: ne mountold a teljes `/mc`-t; csak `-v ~/mc-data/world:/mc/world`.  
- **`Failed to verify username!`**: állítsd `online-mode=false` + `enforce-secure-profile=false` (TLauncher).  
- **`nano` nem található**: a konténer minimál — a **hoston** szerkeszd a `~/mc-data/world/server.properties`-t.  
- **„A Minecraft Server” cím**: a `server.properties` `motd` sorában módosítható.  
- **OP nem működik**: használd az `op <név>`-et `docker attach mc` után, majd **Ctrl+P, Ctrl+Q**-val lépj ki.

---

Jó játékot! 🎮


![Server Icon](icon.png)
