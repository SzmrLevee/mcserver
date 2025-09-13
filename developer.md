# 👨‍💻 Developer Guide – Minecraft Docker Setup

Ez a dokumentum a **fejlesztőknek / üzemeltetőknek** szól, akik a repót szeretnék bővíteni, karbantartani vagy testreszabni.

---

## 📁 Repo szerkezet

```
.
├─ defaults/              # Alap fájlok (első indításkor seedeljük ideiglenesen)
│  ├─ server.properties   # alapértelmezett konfiguráció
│  └─ server-icon.png     # szerver ikon (opcionális)
├─ Dockerfile             # image build logika
├─ entrypoint.sh          # belépési pont (seeding + indítás)
├─ README.md              # felhasználói dokumentáció
└─ developer.md           # fejlesztői dokumentáció (ez a fájl)
```

---

## 🐳 Dockerfile – fontos részek

- **Base image:** `ubuntu:24.04`
- **Csomagok:** OpenJDK 21, curl, jq, ca-certificates
- **Minecraft szerver JAR letöltés:** mindig a legfrissebb stabil Mojang verziót húzza le a `piston-meta` API-ból.
- **EULA:** `eula=true` automatikusan beírva, külön elfogadás nem kell.
- **defaults/**: az alapfájlokat bemásolja a konténerbe, de nem a `world`-be! Ezeket az `entrypoint.sh` kezeli.
- **Entrypoint:** a `CMD` az `entrypoint.sh`-t hívja, nem közvetlenül a `java -jar`-t.

---

## 🚪 entrypoint.sh – működés

```sh
#!/bin/sh
set -e

if [ ! -f "/mc/server.properties" ]; then
  [ -f "/defaults/server.properties" ] && cp -n /defaults/server.properties /mc/
fi

if [ ! -f "/mc/server-icon.png" ] && [ -f "/defaults/server-icon.png" ]; then
  cp -n /defaults/server-icon.png /mc/
fi

exec java ${JAVA_OPTS:- -Xms1G -Xmx2G} -jar /mc/server.jar nogui
```

### Mit csinál?
1. **set -e**: hibánál azonnal álljon le.
2. Ha nincs `server.properties` → seedel a `/defaults/`-ból.
3. Ha nincs `server-icon.png` → szintén seedel a `/defaults/`-ból.
4. `exec java …` – átadja a folyamatot a Java szervernek.

Ez biztosítja, hogy:
- Az első indításkor **mindig legyen működő konfiguráció**.
- A hoston lévő világ (`~/mc-data/world`) **nem írja felül** a szerverfájlokat.

---

## 🔄 Build & Run – fejlesztői mód

```bash
# build
docker build -t mc-server:latest .

# töröld a régit, ha fut
docker rm -f mc 2>/dev/null || true

# futtasd újra
docker run -it --rm -p 25565:25565 -v ~/mc-data/world:/mc/world mc-server:latest
```

Fejlesztőként gyakran hasznos az `--rm` és az `-it` (interaktív futtatás).

---

## 🧪 Tesztelés

- **Unit tesztek** itt nincsenek – a "teszt" az, hogy elindul-e a szerver és seedelődik-e a `server.properties` és `server-icon.png`.
- A legegyszerűbb teszt: töröld a host `~/mc-data/world/server.properties` fájlt, majd indítsd a konténert → látnod kell, hogy az alapértelmezett bekerül.

---

## 🚀 Release folyamat

1. Frissítsd a `Dockerfile`-t, ha új Java vagy Mojang változás kell.
2. Lokál build: `docker build -t mc-server:latest .`
3. Teszteld Mac + Linux környezetben (Windowsnál a mount elérési út más).
4. Ha minden jó, pushold a repóba.

---

## ❗ Fontos különbség a README-hez képest

- A **README.md** a **felhasználóknak** szól (hogyan futtassák).  
- A **developer.md** a **fejlesztőknek / maintainer-eknek** szól (hogyan működik a build és a seeding).

---

## ✅ Röviden

- Az **entrypoint.sh kötelező**, mert abban történik a **seeding logika**.  
- A világot **csak mountoljuk** (`/mc/world`), minden más a konténerben van.  
