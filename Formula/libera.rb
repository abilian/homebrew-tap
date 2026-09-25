class Libera < Formula
  include Language::Python::Virtualenv

  desc "Abilian's desktop office suite"
  homepage "https://docs.liberasuite.eu/"
  url "https://files.pythonhosted.org/packages/12/fc/a2f0e83617f04895f5db34546786424a91d108bb3a4591fb820130c8a13e/libera-0.2.1.tar.gz"
  sha256 "ebea2ff86e7d46bb3069683f16bcb74d80e349476b26d5ecf29792b0f6bc17ac"
  license "Apache-2.0"

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "python@3.13"

  on_macos do
    # The editors are not in the wheel. `libera --payload-install`
    # fetches about 170 MB from the payload origin on first use and verifies every
    # artifact against the SHA-256 in the manifest the wheel carries.

    resource "pyobjc-core" do
      url "https://files.pythonhosted.org/packages/a5/78/abc4ce5920305780aeb36b4067a86253378b36e29ba96673a3deb02eb03a/pyobjc_core-12.2.2.tar.gz"
      sha256 "3906452339cd06a3bb07df103c2511d4cb0f7a22d8771c0b802eba15d9a642b6"
    end

    resource "pyobjc-framework-cocoa" do
      url "https://files.pythonhosted.org/packages/75/76/49c6da2c6a831020b4854ba20079d5a1030474bffc776b7b73c2eeff8c15/pyobjc_framework_cocoa-12.2.2.tar.gz"
      sha256 "c96c0ef69a71afbbb0e6a7d594b455c5fe47d62e0db376ee7a2b4b828c16ace9"
    end

    resource "pyobjc-framework-quartz" do
      url "https://files.pythonhosted.org/packages/35/b1/426a37c7ae37280b3ffca2571fb48f211946aee2f4ca31a603ed1943c4a7/pyobjc_framework_quartz-12.2.2.tar.gz"
      sha256 "810f97b210cfd93704d240860286dfd6df09f9f1c52525fc5c2166723aea3f9e"
    end

    resource "pyobjc-framework-security" do
      url "https://files.pythonhosted.org/packages/c2/92/c304b7fc3a0fe7484a2a3cf25711e70c8fa2b6969d82f4010e35b9af2164/pyobjc_framework_security-12.2.2.tar.gz"
      sha256 "33efab1ff7d18570148f8f3ddd44eca305f733aee00b9115d5263bef81018f65"
    end

    resource "pyobjc-framework-uniformtypeidentifiers" do
      url "https://files.pythonhosted.org/packages/70/c6/31ac40c4d918baa36ca06d196bfec0f47f804a74684988cf424060469d98/pyobjc_framework_uniformtypeidentifiers-12.2.2.tar.gz"
      sha256 "12f8ba77dcc949ffb9f0f48743cae326aebec8e69cb1ac55a1d1e04dca7bd59a"
    end

    resource "pyobjc-framework-webkit" do
      url "https://files.pythonhosted.org/packages/6f/1f/766e338197f7051c25f23cb0d350caa88234b31c3a759127f2cbb67f3376/pyobjc_framework_webkit-12.2.2.tar.gz"
      sha256 "e5588df2a73b377b59a994cc2a78b467e4341f4e4d28b52e8671e21a2811d3c1"
    end
  end

  on_linux do
    # pywebview's GTK backend, as for terminux. On Linux the Flatpak
    # bundle is the better install -- it brings its own GTK, WebKit and payload --
    # and this formula is here for a machine that already lives in Homebrew.
    depends_on "gtk+3"
    depends_on "pygobject3"
    depends_on "webkitgtk"
  end

  resource "bottle" do
    url "https://files.pythonhosted.org/packages/7a/71/cca6167c06d00c81375fd668719df245864076d284f7cb46a694cbeb5454/bottle-0.13.4.tar.gz"
    sha256 "787e78327e12b227938de02248333d788cfe45987edca735f8f88e03472c3f47"
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
    virtualenv_install_with_resources
  end

  test do
    assert_match "libera #{version}", shell_output("#{bin}/libera --version")
  end
end
