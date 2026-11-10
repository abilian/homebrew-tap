class Terminux < Formula
  include Language::Python::Virtualenv

  desc "Cross-platform desktop terminal with workspaces and tabs"
  homepage "https://pypi.org/project/terminux/"
  url "https://files.pythonhosted.org/packages/32/18/1986056544d00fd265b25a8d716031de990b57b3568e3ae6a04050b9b138/terminux-0.11.0.tar.gz"
  sha256 "cfc08cb4bb574bc8cfe22d650eb3b2e2d899e3590b59f53f92c1199506422fbb"

  depends_on "python@3.13"

  on_macos do
    resource "pyobjc-core" do
      url "https://files.pythonhosted.org/packages/83/58/7bab095330b8893e1ac58f3cf9710462c3242b600f8fa5db0d5dda795775/pyobjc_core-13.0.tar.gz"
      sha256 "ffe154462d14aa4852f424e9116f17b5f8d44f78fc0f6c4727e721a5fa7177da"

      patch <<~EOS
        pyobjc-core builds one test-only extension (PyObjCTest.block2) with
        -fdisable-block-signature-string, which Apple clang 16 and older reject.
        Every toolchain that runs on macOS 14 (Xcode <= 16.2) is that old, so the
        source build fails there. Nothing outside pyobjc's own test suite loads
        this extension; dropping the flag only changes how it is compiled.
        --- a/Modules/objc/test/block2.m
        +++ b/Modules/objc/test/block2.m
        @@ -1,3 +1,2 @@
         /*
        - * CFLAGS: -fdisable-block-signature-string
          */
      EOS
    end

    resource "pyobjc-framework-cocoa" do
      url "https://files.pythonhosted.org/packages/30/50/55a8779d35f1f86d795264cbd6fe62e35b2cf4fb8343fc888e99268c988a/pyobjc_framework_cocoa-13.0.tar.gz"
      sha256 "bb7a23941fc8d7866578dbc84e56140efd343a1d28510f530dd1dbf80807daf4"
    end

    resource "pyobjc-framework-quartz" do
      url "https://files.pythonhosted.org/packages/7a/86/ffaa76ca28df5450cce14614c657b910bbd7bb737feaf47f74230c3b78d3/pyobjc_framework_quartz-13.0.tar.gz"
      sha256 "b9a4942182efbbc7e18e6cb7f5a8faa166dc2fc5e33bece7c7b1355494274add"
    end

    resource "pyobjc-framework-security" do
      url "https://files.pythonhosted.org/packages/63/3a/58e0d6ef73812d279a89858ffd06b64d08eebe30bf84441c4b4df6e9665d/pyobjc_framework_security-13.0.tar.gz"
      sha256 "e5c3f90773fb53dcd525075011f80a83e6f38cb0ad0bcd13fb8f629bf35d22aa"
    end

    resource "pyobjc-framework-uniformtypeidentifiers" do
      url "https://files.pythonhosted.org/packages/ba/3d/ab2b17b2d31286c405bc7d818cf85de538bd90144cd3163c693b0de1d623/pyobjc_framework_uniformtypeidentifiers-13.0.tar.gz"
      sha256 "d70ae3722c91c57de71a77d1004a22a118e38798f66c30552cb93754f7a9cbb5"
    end

    resource "pyobjc-framework-webkit" do
      url "https://files.pythonhosted.org/packages/5c/c3/8cf2bd403676ac956046150c666357f3eaf246e936bfd29069dba59534ce/pyobjc_framework_webkit-13.0.tar.gz"
      sha256 "80debaa16c416895214c74e483bd13f510fc0965e4def34653e37705a5eef1a6"
    end
  end

  on_linux do
    # pywebview's GTK backend. The GObject/cairo bindings come from
    # Homebrew (pygobject3 pulls py3cairo + gobject-introspection); pip-building
    # them is impractical (meson toolchain under Homebrew's --no-binary). The
    # --system-site-packages virtualenv imports them; GTK 3 + WebKit2GTK supply
    # the runtime typelibs.
    depends_on "gtk+3"
    depends_on "pygobject3"
    depends_on "webkitgtk"
  end

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/a1/98/7e457a3b014976887a050561955c0b76e1e7e2d6e27b78ecef2ef80518f2/anyio-4.16.0.tar.gz"
    sha256 "59bb03251907983d1603d27c3087ddb1e93299ea2163adcdba37899a4fb12ffb"
  end

  resource "bottle" do
    url "https://files.pythonhosted.org/packages/7a/71/cca6167c06d00c81375fd668719df245864076d284f7cb46a694cbeb5454/bottle-0.13.4.tar.gz"
    sha256 "787e78327e12b227938de02248333d788cfe45987edca735f8f88e03472c3f47"
  end

  resource "click" do
    url "https://files.pythonhosted.org/packages/45/37/edbf1b0707709013c0cf2e8317e03d97ed29bf4cac709fe328904ae92a38/click-8.5.1.tar.gz"
    sha256 "9bbfada76703fd1d784b83eea012e3e8c6a001a876543ef104fa56aaaeb072b4"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz"
    sha256 "4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/f5/08/8eea9d4b8302028f3abb2c0813953f7aec26d33b7a8960ed760e65ff29fa/idna-3.20.tar.gz"
    sha256 "a7db850025b95ded1eae8a46181a1a6c56c92c96f0e2b005d9ff8dc0210cab44"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/d7/9a/8475be631fb33ca1466915e70fd594c42a4e84b512db650eaa14f90fe75d/platformdirs-4.14.5.tar.gz"
    sha256 "32e9921db7385aa8169bee4fe9501923e5715ba9fb7ea3b9c69b0d8e0639f7a1"
  end

  resource "proxy-tools" do
    url "https://files.pythonhosted.org/packages/f2/cf/77d3e19b7fabd03895caca7857ef51e4c409e0ca6b37ee6e9f7daa50b642/proxy_tools-0.1.0.tar.gz"
    sha256 "ccb3751f529c047e2d8a58440d86b205303cf0fe8146f784d1cbcd94f0a28010"
  end

  resource "ptyprocess" do
    url "https://files.pythonhosted.org/packages/20/e5/16ff212c1e452235a90aeb09066144d0c5a6a8c0834397e03f5224495c4e/ptyprocess-0.7.0.tar.gz"
    sha256 "5c5d0a3b48ceee0b48485e0c26037c0acd7d29765ca3fbb5cb3831d347423220"
  end

  resource "pywebview" do
    url "https://files.pythonhosted.org/packages/59/4a/05307135dafba67778669d194bd1a3822a7685ec9ee8a6d7e70856c1a551/pywebview-6.2.1.tar.gz"
    sha256 "71b7136752e40824655304d938efb62014218d1a90bd8e87e1cbdb1ce9c466af"
  end

  resource "starlette" do
    url "https://files.pythonhosted.org/packages/48/bb/3d8757f21e9a53d9035c9eb039a777047139a16bfdbedfc7a58241c3d914/starlette-1.10.0.tar.gz"
    sha256 "b8399098d4c1e3522734f7235dc79b1fc967f96cf139c81e0fa30479e0685f9b"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "uvicorn" do
    url "https://files.pythonhosted.org/packages/da/34/30e9280707135d2cfc589dfff3cb796bd07a3aeb1a3e415ba09dd89d7bb4/uvicorn-0.54.0.tar.gz"
    sha256 "a2e33cbfaa0306f8e6b0c13e0cb89d7d7a2da3e62b90c66e18c33d9807b28620"
  end

  resource "websockets" do
    url "https://files.pythonhosted.org/packages/75/79/590c5f0cc7d1661195aeefccb0e342b79f4c77d368d526d028821a390332/websockets-17.4.tar.gz"
    sha256 "09d3939b70df0c8ad2da145ebd50978bccaee1d565e838b0e7921a34d38571eb"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "terminux", shell_output("#{bin}/terminux --help")
  end
end
