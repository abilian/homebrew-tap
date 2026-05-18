class Terminux < Formula
  include Language::Python::Virtualenv

  desc "Cross-platform desktop terminal with workspaces and tabs"
  homepage "https://pypi.org/project/terminux/"
  url "https://files.pythonhosted.org/packages/b3/83/6550967757bfba589fb27f6622561436f817a6d1bb82095303235c37d3ec/terminux-0.1.0.tar.gz"
  sha256 "32aeae8408b53817a92fe0e87080d36b3a23107aae26ad5b9a19b3165cf22ea4"

  depends_on "python@3.13"

  on_macos do
    resource "pyobjc-core" do
      url "https://files.pythonhosted.org/packages/b8/b6/d5612eb40be4fd5ef88c259339e6313f46ba67577a95d86c3470b951fce0/pyobjc_core-12.1.tar.gz"
      sha256 "2bb3903f5387f72422145e1466b3ac3f7f0ef2e9960afa9bcd8961c5cbf8bd21"
    end

    resource "pyobjc-framework-cocoa" do
      url "https://files.pythonhosted.org/packages/02/a3/16ca9a15e77c061a9250afbae2eae26f2e1579eb8ca9462ae2d2c71e1169/pyobjc_framework_cocoa-12.1.tar.gz"
      sha256 "5556c87db95711b985d5efdaaf01c917ddd41d148b1e52a0c66b1a2e2c5c1640"
    end

    resource "pyobjc-framework-quartz" do
      url "https://files.pythonhosted.org/packages/94/18/cc59f3d4355c9456fc945eae7fe8797003c4da99212dd531ad1b0de8a0c6/pyobjc_framework_quartz-12.1.tar.gz"
      sha256 "27f782f3513ac88ec9b6c82d9767eef95a5cf4175ce88a1e5a65875fee799608"
    end

    resource "pyobjc-framework-security" do
      url "https://files.pythonhosted.org/packages/80/aa/796e09a3e3d5cee32ebeebb7dcf421b48ea86e28c387924608a05e3f668b/pyobjc_framework_security-12.1.tar.gz"
      sha256 "7fecb982bd2f7c4354513faf90ba4c53c190b7e88167984c2d0da99741de6da9"
    end

    resource "pyobjc-framework-uniformtypeidentifiers" do
      url "https://files.pythonhosted.org/packages/65/b8/dd9d2a94509a6c16d965a7b0155e78edf520056313a80f0cd352413f0d0b/pyobjc_framework_uniformtypeidentifiers-12.1.tar.gz"
      sha256 "64510a6df78336579e9c39b873cfcd03371c4b4be2cec8af75a8a3d07dff607d"
    end

    resource "pyobjc-framework-webkit" do
      url "https://files.pythonhosted.org/packages/14/10/110a50e8e6670765d25190ca7f7bfeecc47ec4a8c018cb928f4f82c56e04/pyobjc_framework_webkit-12.1.tar.gz"
      sha256 "97a54dd05ab5266bd4f614e41add517ae62cdd5a30328eabb06792474b37d82a"
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
    url "https://files.pythonhosted.org/packages/19/14/2c5dd9f512b66549ae92767a9c7b330ae88e1932ca57876909410251fe13/anyio-4.13.0.tar.gz"
    sha256 "334b70e641fd2221c1505b3890c69882fe4a2df910cba14d97019b90b24439dc"
  end

  resource "bottle" do
    url "https://files.pythonhosted.org/packages/7a/71/cca6167c06d00c81375fd668719df245864076d284f7cb46a694cbeb5454/bottle-0.13.4.tar.gz"
    sha256 "787e78327e12b227938de02248333d788cfe45987edca735f8f88e03472c3f47"
  end

  resource "click" do
    url "https://files.pythonhosted.org/packages/23/e4/796662cd90cf80e3a363c99db2b88e0e394b988a575f60a17e16440cd011/click-8.4.0.tar.gz"
    sha256 "638f1338fe1235c8f4e008e4a8a254fb5c5fbdcbb40ece3c9142ebb78e792973"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz"
    sha256 "4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/82/77/7b3966d0b9d1d31a36ddf1746926a11dface89a83409bf1483f0237aa758/idna-3.15.tar.gz"
    sha256 "ca962446ea538f7092a95e057da437618e886f4d349216d2b1e294abfdb65fdc"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/9f/4a/0883b8e3802965322523f0b200ecf33d31f10991d0401162f4b23c698b42/platformdirs-4.9.6.tar.gz"
    sha256 "3bfa75b0ad0db84096ae777218481852c0ebc6c727b3168c1b9e0118e458cf0a"
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
    url "https://files.pythonhosted.org/packages/81/69/17425771797c36cded50b7fe44e850315d039f28b15901ab44839e70b593/starlette-1.0.0.tar.gz"
    sha256 "6a4beaf1f81bb472fd19ea9b918b50dc3a77a6f2e190a12954b25e6ed5eea149"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/72/94/1a15dd82efb362ac84269196e94cf00f187f7ed21c242792a923cdb1c61f/typing_extensions-4.15.0.tar.gz"
    sha256 "0cea48d173cc12fa28ecabc3b837ea3cf6f38c6d1136f85cbaaf598984861466"
  end

  resource "uvicorn" do
    url "https://files.pythonhosted.org/packages/f6/b1/8e7077a8641086aea449e1b5752a570f1b5906c64e0a33cd6d93b63a066b/uvicorn-0.47.0.tar.gz"
    sha256 "7c9a0ea1a9414106bbab7324609c162d8fa0cdcdcb703060987269d77c7bb533"
  end

  resource "websockets" do
    url "https://files.pythonhosted.org/packages/04/24/4b2031d72e840ce4c1ccb255f693b15c334757fc50023e4db9537080b8c4/websockets-16.0.tar.gz"
    sha256 "5f6261a5e56e8d5c42a4497b364ea24d94d9563e8fbd44e78ac40879c60179b5"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "terminux", shell_output("#{bin}/terminux --help")
  end
end
