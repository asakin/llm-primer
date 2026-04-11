class LlmPrimer < Formula
  desc "Keep pre-warmed Claude Code sessions ready in tmux"
  homepage "https://github.com/asakin/llm-primer"
  url "https://github.com/asakin/llm-primer/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "23fe1fe2c88fffd46173efea9329abfdb1d3338c2883dd38893ae409b3eb1e5a"
  license "MIT"
  version "0.1.0"

  depends_on "tmux"

  def install
    bin.install "bin/primer"
    bin.install "bin/primerd"
  end

  def caveats
    <<~EOS
      llm-primer requires Claude Code (claude CLI) to be installed separately.
      Install it from: https://claude.ai/code

      Quick start:
        primerd start      # start the pool
        primer attach      # attach to a warm session
        primer status      # check pool health

      Optional config (~/.zshrc):
        export PRIMER_POOL_SIZE=3
        export PRIMER_WATCH_DIR=~/path/to/your/vault/_config
        alias cc='primer attach'
    EOS
  end

  test do
    system "#{bin}/primer", "help"
    system "#{bin}/primerd", "help"
  end
end
