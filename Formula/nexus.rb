class Nexus < Formula
  desc "Repository manager for binary software components"
  homepage "https://www.sonatype.org/"
  url "https://github.com/sonatype/nexus-public/archive/release-3.37.3-02.tar.gz"
  sha256 "82e415f2d957fa5adc7dc7de271752067b3bd7b3f9b966f3cfa71ff2d56f519b"
  license "EPL-1.0"

  # As of writing, upstream is publishing both v2 and v3 releases. The "latest"
  # release on GitHub isn't reliable, as it can point to a release from either
  # one of these major versions depending on which was published most recently.
  livecheck do
    url :stable
    regex(/^(?:release[._-])?v?(\d+(?:[.-]\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/gromgit/homebrew-core-mojave/releases/download/nexus"
    sha256 cellar: :any_skip_relocation, mojave: "a9053daf46f8ac509ff688c0c49271af29a1b87f495f2f1d7b3128ea27cd0acb"
  end

  depends_on "maven" => :build
  depends_on arch: :x86_64 # openjdk@8 is not supported on ARM
  depends_on "openjdk@8"

  uses_from_macos "unzip" => :build

  def install
    ENV["JAVA_HOME"] = Formula["openjdk@8"].opt_prefix
    system "mvn", "install", "-DskipTests"
    system "unzip", "-o", "-d", "target", "assemblies/nexus-base-template/target/nexus-base-template-#{version}.zip"

    rm_f Dir["target/nexus-base-template-#{version}/bin/*.bat"]
    rm_f "target/nexus-base-template-#{version}/bin/contrib"
    libexec.install Dir["target/nexus-base-template-#{version}/*"]

    env = {
      JAVA_HOME:  Formula["openjdk@8"].opt_prefix,
      KARAF_DATA: "${NEXUS_KARAF_DATA:-#{var}/nexus}",
      KARAF_LOG:  "#{var}/log/nexus",
      KARAF_ETC:  "#{etc}/nexus",
    }

    (bin/"nexus").write_env_script libexec/"bin/nexus", env
  end

  def post_install
    mkdir_p "#{var}/log/nexus" unless (var/"log/nexus").exist?
    mkdir_p "#{var}/nexus" unless (var/"nexus").exist?
    mkdir "#{etc}/nexus" unless (etc/"nexus").exist?
  end

  service do
    run [opt_bin/"nexus", "start"]
  end

  test do
    mkdir "data"
    fork do
      ENV["NEXUS_KARAF_DATA"] = testpath/"data"
      exec "#{bin}/nexus", "server"
    end
    sleep 100
    assert_match "<title>Nexus Repository Manager</title>", shell_output("curl --silent --fail http://localhost:8081")
  end
end
