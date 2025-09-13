# 🌍 Minecraft Server saját domainen futtatása

Ez a leírás bemutatja, hogyan tudod a Minecraft szerveredet **saját domain név** alatt elérhetővé tenni az interneten.

---

## 🔑 Előfeltételek
- Már fut a Minecraft szervered Dockerben (`mc` konténer).  
- Van egy domain neved (pl. `example.com`).  
- Hozzáférsz a domain DNS beállításaihoz (pl. Cloudflare, GoDaddy, Namecheap, stb.).  
- Tudsz a routeredhez / szerveredhez port forwardot állítani.

---

## 1️⃣ Publikus IP cím ellenőrzése
Nyisd meg:  
👉 https://whatismyipaddress.com  

Itt látod a **publikus IP címedet** (pl. `84.2.123.45`).  
Ez az, amit a domain DNS-ben be kell állítanod.

---

## 2️⃣ DNS beállítások
A domain DNS zónájában hozz létre egy **A rekordot**:

- **Host/Name**: `mc` (vagy amit szeretnél → így lesz `mc.example.com`)  
- **Type**: `A`  
- **Value**: a publikus IP címed (pl. `84.2.123.45`)  
- **TTL**: Auto vagy 300 sec  

Így a `mc.example.com` a te otthoni IP címedre fog mutatni.

---

## 3️⃣ Router port forward
A Minecraft alapértelmezett portja: **25565** (TCP).

Állítsd be a routeredben:  

- **Külső port**: 25565  
- **Belső IP**: a géped helyi IP-je (pl. `192.168.0.10`)  
- **Belső port**: 25565  
- **Protokoll**: TCP  

👉 Ezzel elérhető lesz az otthoni szervered kívülről is.

---

## 4️⃣ Tűzfal beállítás
Ha a gépeden van tűzfal, engedélyezd a 25565-ös TCP portot:

**Linux (ufw):**
```bash
sudo ufw allow 25565/tcp
```

**Windows (PowerShell):**
```powershell
netsh advfirewall firewall add rule name="Minecraft" dir=in action=allow protocol=TCP localport=25565
```

---

## 5️⃣ Csatlakozás domain névvel
Ezután a Minecraft kliensben már a saját domaineddel tudsz csatlakozni:

```
mc.example.com:25565
```

Ha az A rekordot a fő domainre (`@`) állítottad, akkor elég ennyi:

```
example.com:25565
```

---

## 6️⃣ Dinamikus IP kezelése (ha nem fix az IP-d)
Ha az internetszolgáltatód **változó IP-t** ad, akkor a domain időnként "elmászik".  
Megoldások:  

- **DuckDNS (ingyenes)** → https://www.duckdns.org  
- **No-IP (ingyenes + fizetős)** → https://www.noip.com  
- Telepítesz egy kliens programot, ami mindig frissíti a domaint az új IP-re.

---

## 7️⃣ (Opcionális) SRV rekord – ha nem a 25565-ös portot használod
Ha több Minecraft szervert futtatsz különböző portokon, használhatsz **SRV rekordot** a DNS-ben.  
Példa (`play.example.com` → `example.com:25570`):

- **Type**: SRV  
- **Service**: `_minecraft._tcp.play`  
- **Target**: `example.com`  
- **Port**: `25570`  
- **Priority**: 0  
- **Weight**: 5  

Így a játékosnak elég `play.example.com`-ot beírnia port nélkül.

---

## 8️⃣ Online vs Offline mód és domain
- **Online mód (ajánlott)**: biztonságosabb, csak hivatalos Mojang/Microsoft accounttal enged be.  
- **Offline mód (TLauncher)**: NE tedd ki internetre! → bárki beléphet tetszőleges névvel.

---

## ✅ Összefoglalás
1. Szerezz egy domaint.  
2. DNS-ben állíts A rekordot a publikus IP-dre.  
3. Routerben állíts port forwardot 25565/TCP-re.  
4. Engedélyezd a portot a tűzfalon.  
5. Csatlakozz a Minecraft kliensben a domain névvel.  

Most már a szerveredet a saját domaineden keresztül érheted el! 🎮