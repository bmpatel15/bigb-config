# Vendored: Ethereal Omarchy (VS Code theme)

This directory is a **vendored copy** of a third-party VSCodium/VS Code color theme,
kept here so it's tracked in `bigb-config` and reproducible via `install.sh` without
depending on the Microsoft Marketplace (it is not published to Open VSX, which VSCodium
uses by default).

- **Extension:** Ethereal Omarchy (`ethereal-omarchy`, theme label `Ethereal`)
- **Author / publisher:** bjarneo (Bjarne)
- **Source:** https://github.com/bjarneo/ethereal-vscode
- **Marketplace:** https://marketplace.visualstudio.com/items?itemName=Bjarne.ethereal-omarchy

Same author as this system's `ethereal.nvim` colorscheme, so the palette matches the rest
of the Omarchy Ethereal desktop (bg `#060B1E`, fg `#ffcead`, accent `#7d82d9`).

`package.json` and `themes/ethereal-color-theme.json` are copied verbatim from upstream.
To refresh: re-download both files from the `main` branch of the source repo, then rebuild the
`.vsix` (see below).

## Why a `.vsix` (not a symlinked folder)

Modern VSCodium (tested on 1.126) only loads **installed** extensions — it ignores unpacked or
symlinked folders dropped into `~/.vscode-oss/extensions/`. So the sibling `../ethereal-omarchy.vsix`
is the actual install artifact; `install.sh vscodium` installs it via
`codium --install-extension`. This unpacked folder is kept only as the readable, git-diffable source.

**Rebuild `../ethereal-omarchy.vsix` after editing files here:**

```sh
cd "$(mktemp -d)" && mkdir extension
cp -a <this-dir>/package.json <this-dir>/themes extension/
cat > extension.vsixmanifest <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
  <Metadata>
    <Identity Language="en-US" Id="ethereal-omarchy" Version="1.0.0" Publisher="Bjarne" />
    <DisplayName>Ethereal Omarchy</DisplayName>
    <Description xml:space="preserve">Ethereal vscode theme</Description>
    <Tags>theme,color-theme,ethereal,omarchy</Tags>
    <Categories>Themes</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.70.0" /></Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code" /></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" /></Assets>
</PackageManifest>
XML
cat > '[Content_Types].xml' <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="application/json" />
  <Default Extension="vsixmanifest" ContentType="text/xml" />
</Types>
XML
zip -r -X <this-dir>/../ethereal-omarchy.vsix '[Content_Types].xml' extension.vsixmanifest extension
```
