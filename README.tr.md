# SmartPSS Lite'ı Linux'ta çalıştırma (Wine)

[English](README.md) | **Türkçe**

Dahua'nın Windows için ücretsiz yayınladığı **SmartPSS Lite** (V1.006.0000000.1, 64-bit) programını Linux'ta
Wine ile çalıştıran kurulum betikleri ve belgeler. Resmi bir Linux sürümü **değildir**, Dahua ile bağlantısı yoktur, destek garantisi verilmez.

> **Bu depo Dahua SmartPSS Lite'ı veya Microsoft VC++ runtime'ını İÇERMEZ.** Yalnızca betikler ve belgeler vardır.
> SmartPSS Lite'ı **dahuasecurity.com**'dan kendiniz indirirsiniz (aşağıda). **Dahua Wiki'deki sürüm eskidir, kullanmayın.**

## Durum

| | |
|---|---|
| Test edilen sistemler | Debian 13 (XFCE/Xorg), Pardus 25 (GNOME/Wayland), Devuan 6 (GNOME/Wayland); en az 3 farklı bilgisayar. Hepsi WineHQ stable ile (Devuan 6'da WineHQ'nun Debian 13/trixie deposuyla) |
| Wine | WineHQ stable 11.0 |
| Çalıştığı doğrulananlar | İlk kurulum (admin hesabı), cihaz ekleme (IP ve seri no/P2P), cihazın web arayüzü, canlı izleme |
| Test edilmeyenler | Kayıt oynatma, uzun süreli kullanım, çok sayıda kamera, dağıtımın kendi Wine paketi (Debian 13'te Wine 10) |
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

SmartPSS Lite'ı yalnızca **[dahuasecurity.com](https://www.dahuasecurity.com)** (Dahua'nın resmi sitesi, indirme bölümü) üzerinden
indirin: "SmartPSS Lite" aratıp Windows 64-bit paketini alın ve bu klasörün içine koyun.
**Dahua Wiki'den indirmeyin, kullanmayın:** oradaki SmartPSS Lite sürümü eskidir (outdated) ve bu betiklerle test edilmemiştir.

Test edilen dosya:

```
General_SmartPSSLite_MultiLang_Win64-Install_IS_V1.006.0000000.1.R.260305.zip
SHA-256: b7c716eefadf2993a84f28adec56e6f29f7a2dbb855e16caee697ccfc2014130
```

Doğrulamak için: `sha256sum General_SmartPSSLite_*.zip`. Başka sürümlerle denenmedi, çalışmayabilir.
Zip başka bir yerdeyse: `SMARTPSS_ZIP=/yol/dosya.zip ./setup.sh`.

### 3. Wine'ı kurun (kurulu değilse)

Debian/Ubuntu tabanlı sistemlerde (`sudo` ve internet gerekir):

```bash
./wine-kur.sh
```

Varsayılan olarak resmi **WineHQ** deposunu ekler ve `winehq-stable` paketini kurar
(`sudo apt install --install-recommends winehq-stable`), ayrıca `7z` ve `unzip` kurar. Test edilen kurulum budur.

- Debian tabanlılarda (Debian, Devuan, Pardus ...) WineHQ çalışmazsa yedek olarak dağıtımın kendi Wine paketi
  (`wine wine64 libwine fonts-wine`) kurulur. SmartPSS Lite ile denenmemiştir.
- Kaynağı zorlamak için: `WINE_SOURCE=winehq ./wine-kur.sh` veya `WINE_SOURCE=distro ./wine-kur.sh`.

Başka dağıtımlarda Wine'ı [WineHQ yönergeleriyle](https://gitlab.winehq.org/wine/wine/-/wikis/Download) kurun.
Kontrol: `wine --version` (en az Wine 9 gerekir, 11 önerilir).

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

Betikler mesajları İngilizce verir; sistem dili Türkçeyse Türkçe verir.

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
