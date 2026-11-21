class Libera < Formula
  include Language::Python::Virtualenv

  desc "Abilian's desktop office suite"
  homepage "https://docs.liberasuite.eu/"
  url "https://files.pythonhosted.org/packages/40/90/25fefe0b70badf148c5ef760175a0e2659947525da4b42eee88e3bee408b/libera-0.7.3.tar.gz"
  sha256 "2b3b0370dfb61afda8513ae916b1bee84dae14c181c83bbc4941e93e230dc233"
  license "Apache-2.0"

  depends_on "python@3.13"

  on_macos do
    # The components come with it, as two packages: libera-core, the
    # converter, a binary wheel per platform, and libera-web, the editors and fonts.

    resource "libera-core" do
      url "https://files.pythonhosted.org/packages/20/5e/0411a8f6be5405037adde39578e6d0bf1d12761f91ca49efade5208d2889/libera_core-0.7.3-py3-none-macosx_14_0_arm64.whl"
      sha256 "81105f1f3dc3c2e1ad48ea9b60e16d2c97e7f756cf441700451ed402d0aadded"
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
      url "https://files.pythonhosted.org/packages/bc/a6/761e674f8c88989d9adb7755e7450040dc1f948fcd90d581f7c1bca73364/libera_core-0.7.3-py3-none-manylinux_2_34_x86_64.whl"
      sha256 "8073e315dc1d83c0e8ce3572472c376dece05fd4397cdf3d165f0ad7f4fa2898"
    end
  end

  resource "bottle" do
    url "https://files.pythonhosted.org/packages/7a/71/cca6167c06d00c81375fd668719df245864076d284f7cb46a694cbeb5454/bottle-0.13.4.tar.gz"
    sha256 "787e78327e12b227938de02248333d788cfe45987edca735f8f88e03472c3f47"
  end

  resource "libera-web" do
    url "https://files.pythonhosted.org/packages/4f/d3/397cbb3af79585d045af3bddb22f7ae8157e6ce27966796ff19020bafe73/libera_web-0.7.3-py3-none-any.whl"
    sha256 "7d122f8da2a2fa2746511bb25293337f1ea1140db13db329f5ab281763212085"
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
