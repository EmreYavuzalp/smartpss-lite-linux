> Not: Bu dosya geliştirme sırasında tutulan ham çalışma günlüğüdür (Türkçe). Güncel kullanım için ../README.md dosyasına bakın.

# SmartPSS Lite (Dahua) -> Linux: çalışma notları

Amaç: Windows'a özel Dahua SmartPSS Lite V1.006.0000000.1 (build 2026-03-05, Win64) uygulamasını Linux'ta çalıştırmak.
Bu dosya, başka bir kişi/AI'nın kaldığımız yerden devam edebilmesi için yazıldı. Son güncelleme: 2026-10-20.

## Ortam
- Linux 6.12 (Debian 13), x86_64, Wine 11.0 (`/opt/wine-stable`), X11 oturumu.
- Proje dizini: `<proje-dizini>`
- Dizin yapısı:
  - `General_SmartPSSLite_...exe.zip` : orijinal indirme (zip içinde NSIS installer .exe)
  - `extract/` : zip'ten çıkan installer .exe
  - `app/` : installer'ın 7z ile açılmış hali (656 MB, ~135 dosya). Orijinal/temiz kopya, dokunulmuyor.
  - `prefix/` : özel Wine prefix'i (WINEPREFIX), `WINEARCH=win64`. `~/.wine`'a dokunulmadı.
    - `prefix/drive_c/Program Files/SmartPSSLite/` : `app/` içeriğinin kopyası (uygulama burada çalışıyor)
    - `prefix/drive_c/users/Public/SmartPSSLite/` : kullanıcı verisi (Conf/User, Data/User/Database, Log)
  - `backup/` : bozuk ilk kullanıcı verisi yedeği
  - `NOTES.md` : bu dosya

## Karar: neden native port değil, Wine
- Ana uygulama `SmartPSSLite.exe`: Qt5 (5.x) C++ , kaynak kodu yok, 64-bit PE.
- Bağımlılıklar kapalı kaynak Windows DLL'leri: `dhnetsdk.dll`, `dhconfigsdk.dll`, `play.dll`, `avnetsdk.dll`,
  `dllmav*codec.dll`, `P2PDll.dll`, `EncryptSqlite.dll` (şifreli sqlite), `libmariadb.dll`, Oracle oci*.dll vb.
- Bunların Linux karşılığı yok; reverse engineering ile tüm uygulamayı Linux'a native derlemek pratik değil.
  Dahua'nın Linux NetSDK'sı ayrı bir ürün ve bu GUI uygulamasının ABI'sine uymaz.
- Seçilen yol: Wine + özel prefix + launcher. (Kullanıcı bahsettiği https://github.com/morluto/rea
  "Reverse Engineer Anything" MCP aracı: sadece README'ye bakıldı, kullanılmadı. Gerekirse DLL içi analiz için kullanılabilir.)

## Yapılanlar (kronolojik)
1. Zip açıldı: tek dosya, NSIS installer (`file` çıktısı: "Nullsoft Installer self-extracting archive").
2. `7z x` ile installer içeriği `app/` altına çıkarıldı (`$PLUGINSDIR` installer'a ait, prefix'e kopyalanırken silindi).
3. `WINEPREFIX=$PWD/prefix WINEARCH=win64 wineboot -u` ile yeni prefix oluşturuldu.
4. `app/*` -> `prefix/drive_c/Program Files/SmartPSSLite/` kopyalandı (installer çalıştırılmadı; installer'ın yaptığı
   kayıt defteri/kısayol işleri yapılmadı, şimdilik gerekmedi).
5. `cd "Program Files/SmartPSSLite" && wine SmartPSSLite.exe` -> uygulama açıldı.

## Sorun 1 (ÇÖZÜLDÜ): İlk açılışta hesap oluşturma yerine login ekranı
- Belirti: İlk çalıştırmada "admin hesabı oluştur" ekranı yerine doğrudan login geliyordu.
- Kök neden (log: `C:\Users\Public\SmartPSSLite\Log\client_log\*.log`):
  - Uygulama kullanıcı verisini `C:\Users\Public\SmartPSSLite\{Conf,Data}\User` altında tutar.
  - İlk çalıştırmada `Data/User/Database/` dizini yoktu; `MoveFiles(): File [...AccessControl.db] copy failed!`,
    `sqlite3_openwithencrypt not Success`, `UserMgrDBParser::CreateTables(): !m_pDatabase`,
    `dhMkDir ...Picture/IvsPic return err` hataları. Yani dizinler oluşturulamadı, `RoleUserInfoData.db` (kullanıcı/rol
    veritabanı) kurulamadı, uygulama "kullanıcı yok" durumunu yanlış yorumlayıp login'e düştü.
  - Uygulamanın kendi `dhMkDir`'i iç içe (recursive) dizin oluşturamıyor gibi (Wine altında).
- Çözüm: `C:\Users\Public\SmartPSSLite` yedeklenip (`backup/`) silindi, şu dizinler ÖNCEDEN oluşturuldu, sonra uygulama başlatıldı:
  ```
  Conf/User/OrganizationBackup
  Data/User/Database/{Log,LocalRes}
  Data/User/Picture/{Capture,AccessCapture,FacePictures,HumanTraitPictures,FaceGather,IvsPic}
  Data/User/Record
  Log/{client_log,sdk_log}
  ```
  (hepsi `prefix/drive_c/users/Public/SmartPSSLite/` altında). Sonuç: veritabanları hatasız açıldı,
  kullanıcı hesap oluşturma + gizli soru ekranı geldi ve hesap oluşturuldu. (Not: IvsPic için `dhMkDir ... return err` mesajı
  dizin önceden olsa da log'da kalıyor; zararsız görünüyor.)

## Sorun 2 (KISMEN ÇÖZÜLDÜ / izleniyor): Login sonrası siyah ekran + çökme döngüsü
> ÖZET (en güncel durum): Çökme sebebi kesin kanıtlanmadı. Native Microsoft VC++ runtime (v14.44) kurulup DLL override'ları
> eklendikten sonra kullanıcı cihaz ekleyip canlı izlemeyi açabildi ("Deney: native MS VC++ runtime" bölümüne bak).
> Çökme döngüsü tekrar ederse aşağıdaki bulgu ve hipotezlerle devam et. Aşağıdaki "denenmedi" notları tarihseldir.
- Belirti: Hesap oluşturma sonrası login ekranı geliyor, oto-login seçili; login sonrası ana pencere siyah kalıyor,
  pencere sürekli kapanıp açılıyor.
- Bulgular:
  - Süreç listesinde `SmartPSSLiteDaemon.exe` (watchdog) ve `SmartPSSLite.exe -crash` görülüyor: ana uygulama çöküyor
    ve Daemon `-crash` argümanıyla yeniden başlatıyor. Yaklaşık her 24 sn'de bir yeni log (`SmartPSS-Lite_HH_MM_SS-*.zip`).
  - Uygulama log'unda çökmeden hemen önce: `MainFormWidget::HandleCrash(): crash report process[...SmartPSSLite.exe]`,
    son satırlar ISSHomePageContainer (ana sayfa modül ikonları, `Skin/DustyBlue/HomePage/ISS/*.png`) ve
    SipStack init. Yani çökme ana sayfa (home page) oluşturulduktan sonra, GUI thread'inde.
  - `WINEDEBUG=err+all,+seh`: GUI thread'inde gerçek bir `EXCEPTION_ACCESS_VIOLATION (c0000005)`,
    `rip=0x6fffffc5a718` (okuma, hedef adres ~`0x7f042d810030`), ardından uygulamanın kendi
    `my_exception_handle` (crash handler) devreye giriyor. 0x6fffff... adres aralığı Wine'ın yüklediği PE DLL'lerine ait
    (exe 0x140000000'da). Hangi DLL olduğu henüz kesinleşmedi (modül haritası çıkarma denendi: `WINEDEBUG=+loaddll`,
    sonuç `scratchpad/mods.log` / `a.log` içinde olabilir, kontrol edilmedi).
  - Log'da diğer gürültü (zararsız görünenler): `Language MD5 is not right`, `CUpgrade json format error` (güncelleme
    sunucusu), `duplicate column name` (DB migrasyonu tekrar çalışması), `Dolynk Not Authrized`, `No lock, maybe err`,
    `InitConsoleDebug Failed`, P2P sunucularına bağlantı OK.
- Winedbg ile kesin çökme noktası (`winedbg --file cmds.txt 'C:\Program Files\SmartPSSLite\SmartPSSLite.exe'`,
  cmds.txt: `set $BreakOnFirstChance = 1` / `cont` / `bt` / `info reg` / `quit`):
  - `unsafe_block_from_ptr` (ntdll heap.c:1396) <- `RtlFreeHeap(process heap, ptr)` <- Qt5Gui içinde
    `QPixmap(QString)` -> `QPixmap::load` -> `QPlatformPixmap::fromFile` -> `QImageReader::read` -> iç fonksiyon `free`.
    Yani bir PNG yüklenirken, bu heap'e ait olmayan (veya başlığı bozuk) bir işaretçi free ediliyor.
    Çağıran: `mainformplugin.dll` (ana pencere widget'ları, skin ikonları yükleniyor).
  - Çökme anında son açılan görsel her seferinde `Skin/White/VIMainControlUI/door_open_d.png` idi (20x20 RGBA PNG,
    dosya normal, bozuk değil). Yani sorun dosya değil; heap bozulması / allocator uyuşmazlığı şüphesi.
  - Uygulama bu istisnayı kendi SEH handler'ında yakalıyor (`enter my_exception_handle handle`), Daemon `-crash` ile
    yeniden başlatıyor. Winedbg'de first-chance olarak görünür; her first-chance çökme gerçek ölüm olmayabilir.
  - CRT durumu: uygulama dizininde msvcp140/vcruntime140/ucrtbase YOK -> Wine builtin kullanılıyor
    (`+loaddll`: `system32\MSVCP140.dll`, `vcruntime140.dll`, `ucrtbase.dll` builtin). Ayrıca winsxs sahte `msvcr80/msvcp80`
    bir SDK DLL'i için yükleniyor (eski CRT = farklı heap olasılığı). `Qt5Gui.dll` native (uygulama ile gelen) yükleniyor.
    (Bu analiz sırasında resmi VC++ runtime henüz denenmemişti; sonradan denendi, bkz. "Deney: native MS VC++ runtime".)
  - `WINEDEBUG=warn+heap` heap bozulması uyarısı vermedi (sadece `GetNumaHighestNodeNumber semi-stub`).
- GÜNCEL DURUM (kullanıcı bildirimi, sonraki mesaj): Kullanıcı bir süre sonra "neredeyse her şey açıldı, Devices bölümüne
  geldim, 'Initializing' diyor" dedi; yani çökme döngüsü en azından bazen aşılıyor ve ana ekran/Devices açılıyor.
  Kullanıcı şimdi cihaz eklemeyi deneyecek. Hata ayıklama oturumları arasında `wineserver -k` çalıştırdığımız için
  çalışan oturum kapanmış olabilir: kullanıcı açıkken `wineserver -k` KULLANMA.
- Hipotezler (sırayla denenecek, çökme tekrar ederse):
  1. Ana sayfa/render katmanı: Qt Direct2D/OpenGL/Direct3D yolunda Wine sorunu. Dene:
     - `QT_QPA_PLATFORM=windows:nodirectwrite` / `QT_OPENGL=software` / `QT_ANGLE_PLATFORM=warp` ortam değişkenleri,
       `QT_QPA_PLATFORM=windows` yerine `-platform windows:...`.
     - Winetricks: `d3dcompiler_47`, `d3dx9`, `vcrun2015/2019/2022` (VC++ runtime; uygulama kendi vcruntime DLL'lerini getirmiş mi kontrol et),
       `corefonts`, `gdiplus`, `dxvk` (veya tersine DXVK'sız).
     - Wine `winecfg`: Windows sürümü Win10 yap (varsayılan zaten Win10 olabilir, kontrol et).
  2. Çöken modülün adı bulunup (rip -> DLL) o DLL'e odaklanmak (ör. `play.dll`/`HWDec.dll` video decode, `DSGui.dll`,
     `fisheye.dll`, bir plugin). Plugin listesi: `Conf/System/Plugin.xml`, plugin DLL'leri `plugins/` altında.
     Gerekirse ilgili plugin `Plugin.xml`'den devre dışı bırakılır (ör. video/decoder yükleyen ana sayfa modülü).
  3. Eksik runtime: `Daemon`'un bağımlı olduğu bir şey, `dbghelp.dll` (uygulamanın kendi kopyası var), `msvcp140`, `mfc`.
  4. `winedbg`/`WINEDEBUG=+relay` ile çöken fonksiyonun import ettiği DLL'i bulmak; `objdump -x` ile DLL export/import analizi.
- Dikkat: Wine'ı her denemeden önce `wineserver -k` ile temizle; arka planda Daemon yeniden başlatma yapıyor.

## Yararlı komutlar
```bash
cd <proje-dizini>
export WINEPREFIX=$PWD/prefix WINEDEBUG=-all
wineserver -k                                   # tüm wine süreçlerini öldür
cd "prefix/drive_c/Program Files/SmartPSSLite" && wine SmartPSSLite.exe
# loglar:
ls -t prefix/drive_c/users/Public/SmartPSSLite/Log/client_log/
# ekran görüntüsü (X11): import -window root /path/shot.png  (Wine pencereleri siyah çıkabiliyor)
# çökme analizi:
WINEDEBUG=err+all,+seh,fixme-all wine SmartPSSLite.exe 2>&1 | grep -aE 'c0000005|rip='
```

## Yapılacaklar
- [~] Siyah ekran/çökme: native VC++ runtime sonrası kullanılabilir hale geldi; kök neden kanıtlanmadı, tekrar ederse hipotezlere dön.
- [x] `run.sh` launcher (proje kökü ve `portable/`). `.desktop` kısayolu YAPILMADI (istenirse eklenecek).
- [x] `portable/setup.sh`: temiz prefix + uygulama + VC++ runtime + kullanıcı dizinleri (temiz prefix'te test edildi).
- [x] Ağ/cihaz: P2P ile cihaz eklendi, online, cihaz web arayüzü açıldı. Canlı izleme açılıyor ama yavaş (VNC şüphesi).
- [ ] Canlı izleme performansı: VNC'siz test, DXVK denemesi, alt akış. Kayıt oynatma henüz test edilmedi.
- [ ] Oracle `oraociei19.dll` (197 MB) silinebilir mi? Test edilmedi.

## Başlatma
`./run.sh` (proje kökünde). Prefix: `prefix/`, uygulama: `prefix/drive_c/Program Files/SmartPSSLite`.
Zaten çalışıyorsa tekrar başlatmadan önce `WINEPREFIX=$PWD/prefix wineserver -k` ile kapat.

## Deney: native MS VC++ runtime (Sorun 2)
- `wineserver -k` + GlobalFlag=0x4070 (heap validate) ile çalıştırıldı: Wine heap bozulması UYARISI VERMEDİ, döngü sürdü
  (~28 sn'de bir çökme). Bu yüzden uygulamanın heap'i bozuk olduğundan çok, CRT/allocator uyuşmazlığı veya Wine heap sorunu şüphesi.
  (!!! DÜZELTME: GlobalFlag=0x4070 gereksiz DEĞİL. Sonradan 3+ farklı PC'de yapılan testlerde bu değerin (Wine heap'inin LFH'sini
   kapatan debug bayrakları) siyah ekran + çökme döngüsünü ÖNLEDİĞİ görüldü; `setup.sh` bunu adım 4'te ekler, SİLME. Ben bir ara
   "gereksiz" diye silmiştim, bu yanlıştı; ana prefix'e geri eklendi. Muhtemel kök neden: Wine'ın LFH heap'i + uygulamanın heap kullanımı.)
- Kullanıcı cihazı (seri no ile P2P) ekledi, cihaz ONLINE göründü (ağ/SDK çalışıyor), hemen ardından yine çöktü.
- Resmi `vc_redist.x64.exe` (https://aka.ms/vs/17/release/vc_redist.x64.exe, v14.44.35211) indirildi (`vcredist/`), Wine içinde
  `/install /quiet` ile kuruldu; msvcp140/vcruntime140/concrt140 vb. için `HKCU\Software\Wine\DllOverrides = native,builtin` eklendi.
  Sonuç: Kullanıcı native runtime sonrası çalıştırdı: cihaz (seri no/P2P) ONLINE oldu ve cihazın web arayüzüne SmartPSS
  üzerinden girilebildi (uzak cihaz). Çökme döngüsünün tamamen bitip bitmediği kullanıcıdan henüz net teyit edilmedi.
  Doğrulanan: P2P/cihaz ekleme + cihaz web arayüzü Wine altında çalışıyor. Test edilmeyen: canlı video (play.dll), kayıt oynatma.

## Canlı izleme performansı (yavaş oynatma)
- Canlı izleme Wine altında açılıyor ama yavaş. Ölçüm (top, canlı izleme açıkken): makine 4 çekirdek (Intel UHD 630, Mesa),
  toplam CPU ~%38 user + %20 sys, ~%41 boşta -> CPU tamamen doymuş değil. En yüksek tüketen: `Xtigervncserver` (~%54),
  ardından wine `wined3d` thread (~%30) ve SmartPSS thread'leri (%18-27).
- Oturum bir VNC X sunucusunda (Xtigervnc) çalışıyor: her video karesi VNC ile kodlanıyor -> büyük olasılıkla ana darboğaz.
- Fikirler (denenmedi): (1) fiziksel/yerel ekranda (VNC'siz) dene; (2) uygulamada alt akış (sub stream)/az pencere;
  (3) DXVK ile d3d11 -> Vulkan (Intel Vulkan var; VNC altında present sorunlu olabilir); (4) `PlayConfig.ini`
  `enablevadecode=1` sadece Linux native içindir, Wine'da etkisizdir; (5) `Vaxplayer.ini`/`TSConfig.ini` incelenmedi.

## Taşınabilir paket (yavaş internetli başka PC için)
- `smartpss-lite-linux-portable.tar` (~200 MB): orijinal zip + `vc_redist.x64.exe` + `setup.sh` + `run.sh` + `NOTES.md`.
  Kullanıcı verisi İÇERMEZ. Hedefte: `tar xf ...; cd portable; ./setup.sh; ./run.sh` (wine 64-bit ve 7z kurulu olmalı).
- `setup.sh` temiz bir geçici prefix'te test edildi: prefix, uygulama (134 dosya), native VC++ runtime ve 8 DLL override doğru kuruldu.
  Uygulamanın GUI olarak açılması bu testte denenmedi (ana prefix'te çalıştığı doğrulandı).
- (Eski not düzeltildi) GlobalFlag=0x4070 SİLİNMEMELİ; çökme döngüsünü önleyen ayar budur. Bkz. "Deney: native MS VC++ runtime".

## Disk alanı temizliği
- Prefix ~4,2 GB; en büyük kalemler: çökme dökümü `Program Files/SmartPSSLite/SmartPSS-Lite.dmp-*.dmp` (1,5 GB, çökme döngüsünde
  oluşuyor), `oraociei19.dll` (197 MB, Oracle client; KALDIRMA, açılış bağımlılığı olabilir, test edilmedi), `windows/mono` (234 MB, gereksiz),
  Temp (~330 MB), kurulum zip/vc_redist/tar (~200 MB).
- `portable/cleanup.sh`: yukarıdakileri adım adım onayla siler; hesap/cihaz verisine dokunmaz.
- Sonuç (ikinci PC, kullanıcı çıktısı): Temp, log, Wine Mono (234 MB), zip (175 MB), tar (199 MB), vc_redist (25 MB) silindi
  -> yaklaşık 630 MB boşaldı; prefix 2,3 GB kaldı. İkinci PC'de .dmp çıkmadı. Ana makinedeki 1,5 GB .dmp henüz SİLİNMEDİ
  (kullanıcı onayı bekleniyor). İkinci PC'de zip silindiği için yeniden kurulum paketi tekrar taşınmalı.
