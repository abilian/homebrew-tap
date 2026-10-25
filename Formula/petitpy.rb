class Petitpy < Formula
  desc "Small Python runtime, MicroPython-compatible, written in Zig"
  homepage "https://petitpy.lab.abilian.com/"
  version "0.9.0"
  license all_of: ["MIT", "PSF-2.0"]

  uses_from_macos "unzip"

  on_macos do
    on_arm do
      url "https://files.pythonhosted.org/packages/e2/1c/87516171e93f1b4e94ec04698bfffd2027e8fd82c6ab8cf2d3aac5f36a9a/petitpy-0.9.0-py3-none-macosx_11_0_arm64.whl"
      sha256 "1253e0963f9325ed707f67cffc09afd648c329d8ad875d44844f07d6312d917e"
    end
    on_intel do
      url "https://files.pythonhosted.org/packages/72/fa/357685949ac4722efce4575ff0d992492ee59e0883c9ae63eeb722488280/petitpy-0.9.0-py3-none-macosx_11_0_x86_64.whl"
      sha256 "bbc13a721c088d1823c0e7abc73efc8fdb40bd257bc516ced4e6311fc77af1ca"
    end
  end

  on_linux do
    on_arm do
      url "https://files.pythonhosted.org/packages/2e/b4/79507199cc7ad79b234216c42dc2098d909b2b57a588cac55c1fbfafb0a0/petitpy-0.9.0-py3-none-manylinux_2_17_aarch64.whl"
      sha256 "b3275014e1ab42d61dd141832dc354f2f40056fdcd928271d7daf710534a4706"
    end
    on_intel do
      url "https://files.pythonhosted.org/packages/3e/d9/10c46fb51c3b62bba3c245c85ff18153cd048f345830eb4d75a71de71ed7/petitpy-0.9.0-py3-none-manylinux_2_17_x86_64.whl"
      sha256 "b866885f1f83de2b351ec967c5fe8f5afe1526900ccb37887a7df57800e10e61"
    end
  end

  def install
    # Homebrew unpacks archives by extension, and leaves a .whl as it is.
    system "unzip", "-q", Dir["*.whl"].first
    data = buildpath/"petitpy-#{version}.data"
    bin.install data/"scripts/petitpy"
    bin.install_symlink "petitpy" => "ppy"
    (share/"petitpy").install data/"data/share/petitpy/lib"
  end

  test do
    assert_equal "[1, 2]\n", shell_output("#{bin}/petitpy -c 'import json; print(json.loads(\"[1, 2]\"))'")
  end
end
