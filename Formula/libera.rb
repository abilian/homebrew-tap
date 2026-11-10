class Libera < Formula
  include Language::Python::Virtualenv

  desc "Abilian's desktop office suite"
  homepage "https://docs.liberasuite.eu/"
  url "https://files.pythonhosted.org/packages/a1/bb/be8d119f1a403a57bc4ec8157d571b3901aefae345aa49d279f4ee328925/libera-0.7.0.tar.gz"
  sha256 "48dc881892d14c0c2ff2ef81f39020c951333ce30321a8e66a9de3011c1d1712"
  license "Apache-2.0"

  depends_on "python@3.13"

  on_macos do
    # The components come with it, as two packages: libera-core, the
    # converter, a binary wheel per platform, and libera-web, the editors and fonts.

    resource "libera-core" do
      url "https://files.pythonhosted.org/packages/68/4f/e10351c777e4d70be0a826f858130da09bfae42959c16612089d5f977702/libera_core-0.7.1-py3-none-macosx_14_0_arm64.whl"
      sha256 "3f2b5596bc54c0a9b1a66a7d25fb3ea99ba8f4e8906b140ec4ffb67fd7514632"
    end

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
    # pywebview's GTK backend, as for terminux. On Linux the Flatpak
    # bundle is the better install -- it brings its own GTK and WebKit --
    # and this formula is here for a machine that already lives in Homebrew.
    depends_on "gtk+3"
    depends_on "pygobject3"
    depends_on "webkitgtk"

    resource "libera-core" do
      url "https://files.pythonhosted.org/packages/ec/9a/013c6495a1c9e483147d5d4bc0ec3339d58b621e7baf04a927fdd34850d7/libera_core-0.7.1-py3-none-manylinux_2_34_x86_64.whl"
      sha256 "1cf9947a938f18c916479d9e24602fe7e9c21bda532abf081608d62acae3e58c"
    end
  end

  resource "bottle" do
    url "https://files.pythonhosted.org/packages/7a/71/cca6167c06d00c81375fd668719df245864076d284f7cb46a694cbeb5454/bottle-0.13.4.tar.gz"
    sha256 "787e78327e12b227938de02248333d788cfe45987edca735f8f88e03472c3f47"
  end

  resource "libera-web" do
    url "https://files.pythonhosted.org/packages/0a/0f/37630069e377296090758cab4fb0499bd7c502df0674a04697ee2341f8d7/libera_web-0.7.1-py3-none-any.whl"
    sha256 "2142a7f449b691f83b9978684426034fa181eb3ae0c8c4fee3bb833573c9e4cf"
  end

  resource "proxy-tools" do
    url "https://files.pythonhosted.org/packages/f2/cf/77d3e19b7fabd03895caca7857ef51e4c409e0ca6b37ee6e9f7daa50b642/proxy_tools-0.1.0.tar.gz"
    sha256 "ccb3751f529c047e2d8a58440d86b205303cf0fe8146f784d1cbcd94f0a28010"
  end

  resource "pywebview" do
    url "https://files.pythonhosted.org/packages/59/4a/05307135dafba67778669d194bd1a3822a7685ec9ee8a6d7e70856c1a551/pywebview-6.2.1.tar.gz"
    sha256 "71b7136752e40824655304d938efb62014218d1a90bd8e87e1cbdb1ce9c466af"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  def install
    venv = virtualenv_install_with_resources(without: %w[libera-core])
    # Binary wheels, installed as the files they are: Homebrew would
    # unpack them as source trees, and their sdists build from scratch.
    %w[libera-core].each do |name|
      r = resource(name)
      wheel = buildpath/r.downloader.basename
      cp r.cached_download, wheel
      venv.pip_install wheel
    end
  end

  test do
    assert_match "libera #{version}", shell_output("#{bin}/libera --version")
  end
end
