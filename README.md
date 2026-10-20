# SmartPSS Lite'ı Linux'ta çalıştırma (Wine)

Dahua'nın Windows için ücretsiz yayınladığı **SmartPSS Lite** (V1.006.0000000.1, 64-bit) programını Linux'ta
Wine ile çalıştıran kurulum betikleri ve belgeler. Resmi bir Linux sürümü **değildir**, Dahua ile bağlantısı yoktur, destek garantisi verilmez.

> **Bu depo Dahua SmartPSS Lite'ı veya Microsoft VC++ runtime'ını İÇERMEZ.** Yalnızca betikler ve belgeler vardır.
> SmartPSS Lite'ı Dahua'nın resmi sitesinden kendiniz indirirsiniz (aşağıda).

English summary: scripts to run Dahua SmartPSS Lite (Windows, Qt5) on Linux under Wine in a private Wine prefix.
You must download the installer zip from Dahua yourself; the VC++ runtime is fetched from Microsoft automatically.
Tested on Debian 13 and Pardus 25 with WineHQ 11.0.

## Durum

| | |
|---|---|
| Test edilen sistemler | Debian 13 (XFCE/Xorg), Pardus 25 (GNOME/Wayland), en az 3 farklı bilgisayar |
| Wine | WineHQ 11.0 (kararlı) |
| Çalıştığı doğrulananlar | İlk kurulum (admin hesabı), cihaz ekleme (IP ve seri no/P2P), cihazın web arayüzü, canlı izleme |
| Test edilmeyenler | Kayıt oynatma, uzun süreli kullanım, çok sayıda kamera |
| Bilinen sorun | Canlı izleme yavaş olabilir (VNC/uzak masaüstü altında daha da yavaş). Wine'da donanımsal çözümleme (hardware decode) yok |

## Gereksinimler

- 64-bit (x86_64) Linux. Debian, Ubuntu, Pardus, Linux Mint gibi Debian/Ubuntu tabanlılar için hazır betik var
- Wine 11 (WineHQ kararlı), `7z` (p7zip-full / 7zip), `unzip`, `curl` veya `wget`
- En az 3 GB boş disk alanı (kurulum sonrası ~2,3 GB, `cleanup.sh` ile azalır)
- Ext4 gibi Linux dosya sistemi (NTFS/exFAT üzerinde Wine prefix'i çalıştırmayın)

## Kurulum

### 1. Bu depoyu alın

```bash
git clone https://github.com/EmreYavuzalp/smartpss-lite-linux.git
cd smartpss-lite-linux
```

### 2. SmartPSS Lite'ı indirin

Dahua'nın resmi sitesinden (Dahua Wiki / Download Center'da "SmartPSS Lite" aratın) Windows 64-bit paketini indirip
bu klasörün içine koyun. Test edilen dosya:

```
General_SmartPSSLite_MultiLang_Win64-Install_IS_V1.006.0000000.1.R.260305.zip
SHA-256: b7c716eefadf2993a84f28adec56e6f29f7a2dbb855e16caee697ccfc2014130
```

Doğrulamak için: `sha256sum General_SmartPSSLite_*.zip`. Başka sürümlerle denenmedi, çalışmayabilir.
Zip başka bir yerdeyse `SMARTPSS_ZIP=/yol/dosya.zip ./setup.sh` şeklinde de verebilirsiniz.

### 3. Wine'ı kurun (kurulu değilse)

Debian/Ubuntu tabanlı sistemlerde (`sudo` ve internet gerekir):

```bash
./wine-kur.sh
```

- **Debian, Devuan, Pardus ve diğer Debian tabanlılar:** Önce dağıtımın kendi Wine paketi (`wine wine64 libwine fonts-wine`) kurulur.
  Debian 13'te bu Wine 10'dur. Sürümü 9'dan eskiyse ya da kurulamazsa WineHQ deposundan `winehq-stable` denenir.
- **Ubuntu, Linux Mint, Zorin, Pop!_OS ...:** WineHQ deposundan `winehq-stable` kurulur.
- Kaynağı zorlamak için: `WINE_KAYNAK=dagitim ./wine-kur.sh` veya `WINE_KAYNAK=winehq ./wine-kur.sh`.

> Çalıştığı doğrulanan sürüm **WineHQ 11.0**'dır. Dağıtımın Wine 10 paketiyle kurulum denenmedi, çalışması beklenir ama doğrulanmadı.
> Sorun yaşarsanız `WINE_KAYNAK=winehq ./wine-kur.sh` ile 11'e geçin.

Başka dağıtımlarda Wine'ı [WineHQ yönergeleriyle](https://gitlab.winehq.org/wine/wine/-/wikis/Download) kurun. Kontrol: `wine --version`.
En az Wine 9 gerekir, 11 önerilir.

### 4. Kurun

```bash
./setup.sh
```

Birkaç dakika sürer. Betik şunları yapar:

1. Gereksinimleri kontrol eder (mimari, Wine sürümü, `7z`, disk alanı)
2. Bu klasörde özel bir Wine prefix'i (`./prefix`) oluşturur. `~/.wine`'a dokunmaz
3. Dahua zip'indeki NSIS kurulum dosyasını `7z` ile açıp uygulamayı prefix'e kopyalar (kurulum sihirbazı çalıştırılmaz)
4. Microsoft VC++ runtime'ını (v14) kurar ve `msvcp140`, `vcruntime140` vb. için `native,builtin` override'ı ekler
   (`vc_redist.x64.exe` klasörde yoksa Microsoft'tan indirilir)
5. Wine ayarını yapar (`GlobalFlag`, aşağıya bakın) ve kullanıcı dizinlerini önceden oluşturur
6. Uygulama menüsüne ve masaüstüne "SmartPSS Lite" kısayolu ekler

### 5. Başlatın

Uygulama menüsünden "SmartPSS Lite" ya da:

```bash
./run.sh
```

İlk açılışta yönetici (admin) hesabı ve güvenlik sorusu oluşturmanız istenir.

> `smartpss-lite-linux` klasörünü kurulumdan sonra **taşımayın veya silmeyin**: program ve verileriniz `prefix/` içindedir.
> Taşımak gerekirse önce `./uninstall.sh`, sonra yeni yerde `./setup.sh` (verileriniz silinir).

## Programı kapatma

Normalde pencereyi kapatmanız yeterli. Arka planda `SmartPSSLiteDaemon.exe` çalıştığı için süreçler kalırsa:

```bash
WINEPREFIX="$PWD/prefix" wineserver -k
```

Bu, o prefix'teki bütün Wine süreçlerini sonlandırır (açık oturumu da kapatır). Kontrol: `pgrep -af SmartPSS`.

## Disk alanı

```bash
./cleanup.sh
```

Her adımda onay ister. Çökme dökümlerini (`.dmp`, çökme olursa GB'larca olabilir), geçici dosyaları, log'ları,
Wine Mono'yu (gerekmez) ve kurulum dosyalarını silebilir. Hesap ve cihaz verisine dokunmaz.

Kurulu prefix ~2,3 GB. Kalanın çoğu Wine'ın kendi sistem dosyalarıdır, silinemez.

## Kaldırma

```bash
./uninstall.sh
```

Prefix'i (hesaplar, cihazlar, kayıtlar, ekran görüntüleri dahil) ve kısayolları siler. Onay ister.

## Sorun giderme

| Belirti | Çözüm |
|---|---|
| Açılmıyor / takıldı | `WINEPREFIX="$PWD/prefix" wineserver -k` ardından `./run.sh` |
| Login sonrası siyah ekran, pencere sürekli kapanıp açılıyor | `setup.sh`'ın tamamen bittiğinden emin olun (4. adım bu sorunu önler, aşağıya bakın). Eski bir prefix'te ayarı elle ekleyin |
| İlk açılışta hesap oluşturma yerine direkt login geliyor | Uygulama verisi bozuk kurulmuş. `./uninstall.sh` ve `./setup.sh` (kullanıcı dizinleri bu yüzden önceden oluşturuluyor) |
| Canlı izleme yavaş | VNC/uzak masaüstü kullanıyorsanız yerel ekranda deneyin; alt akış (sub stream) ve daha az pencere kullanın |
| Disk doluyor | `./cleanup.sh` |
| Log'lar (destek/inceleme için) | `prefix/drive_c/users/Public/SmartPSSLite/Log/client_log/` |

## Teknik notlar (ne yapılmış, neden)

Uygulama Qt5 ile yazılmış, kapalı kaynaklı 64-bit Windows programıdır ve Dahua'nın yine kapalı kaynaklı Windows DLL'lerine
(`dhnetsdk.dll`, `play.dll`, vb.) bağlıdır; bu yüzden yerel Linux derlemesi mümkün değildir, çözüm Wine'dır. Ayrıntılı keşif günlüğü
[`docs/NOTES.md`](docs/NOTES.md) içindedir (Türkçe, ham çalışma notları). Kısaca sorunlar ve çözümleri:

1. **İlk açılışta hesap oluşturma atlanıyordu.** Uygulama `C:\Users\Public\SmartPSSLite\...` altında iç içe dizinleri kendisi
   oluşturamıyor (Wine altında); veritabanı kurulamayınca "kullanıcı yok" durumunu yanlış yorumlayıp login'e düşüyordu.
   Çözüm: Gerekli dizinler `setup.sh` ve `run.sh` tarafından önceden oluşturulur.
2. **Login sonrası siyah ekran ve çökme döngüsü.** Skin PNG'leri yüklenirken Qt5Gui içinden `RtlFreeHeap` ile Wine'ın ntdll heap'inde
   erişim ihlali oluşuyor (uygulama bunu kendi crash handler'ında yakalıyor ve Daemon yeniden başlatıyor). İki ayar bunu çözdü:
   - Resmi Microsoft VC++ runtime'ının (native `msvcp140`/`vcruntime140`) kurulması ve override edilmesi.
   - `HKLM\System\CurrentControlSet\Control\Session Manager\GlobalFlag = 0x4070` (heap debug bayrakları; Wine'ın düşük parçalanmalı
     heap'ini devre dışı bırakır). **Silmeyin.** Kök neden kesin kanıtlanmadı, bu bir geçici çözümdür.

## Yasal

- SmartPSS Lite, Dahua Technology'nin ürünüdür; bu depo Dahua ile bağlantılı değildir ve onun dosyalarını dağıtmaz.
- Microsoft Visual C++ Redistributable, Microsoft'a aittir; betik onu Microsoft'un resmi adresinden indirir.
- Bu depodaki betikler ve belgeler MIT lisanslıdır (bkz. `LICENSE`).
- Kamera/kayıt cihazlarınızı yalnızca yetkili olduğunuz ağlarda kullanın.
