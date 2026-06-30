#!/usr/bin/env python3
"""Lightweight Xcode project generator for GlamMeUppStudio."""
import os
import uuid

ROOT = os.path.dirname(os.path.abspath(__file__))
APP = "GlamMeUppStudio"
OUT = os.path.join(ROOT, f"{APP}.xcodeproj", "project.pbxproj")

files = []
for dirpath, _, fnames in os.walk(os.path.join(ROOT, APP)):
    for f in sorted(fnames):
        if f.endswith((".swift", ".json", ".plist")):
            rel = os.path.relpath(os.path.join(dirpath, f), ROOT).replace("\\", "/")
            files.append(rel)

def uid():
    return uuid.uuid4().hex[:24].upper()

refs = {f: uid() for f in files}
bfiles = {f: uid() for f in files if f.endswith(".swift")}
G = {k: uid() for k in [
    "root", "app", "models", "services", "views", "design", "resources", "seed",
    "products", "target", "project", "sources", "frameworks", "resphase",
    "debug", "release", "cfglist", "tcfglist"
]}
for sub in ["Analytics", "Bridal", "Calendar", "Clients", "Expenses", "Kit", "Receipts", "Settings", "ServiceLog"]:
    G[sub] = uid()

L = []
def w(s=""):
    L.append(s)

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {};")
w("\tobjectVersion = 56;")
w("\tobjects = {")

for f, bid in bfiles.items():
    w(f"\t\t{bid} /* {os.path.basename(f)} in Sources */ = {{isa = PBXBuildFile; fileRef = {refs[f]}; }};")

w(f"\t\t{G['products']} /* {APP}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
for f, rid in refs.items():
    ext = os.path.splitext(f)[1]
    ft = {".swift": "sourcecode.swift", ".json": "text.json"}.get(ext, "text.plist.xml")
    w(f"\t\t{rid} /* {os.path.basename(f)} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; name = {os.path.basename(f)}; path = {f}; sourceTree = SOURCE_ROOT; }};")

w(f"\t\t{G['frameworks']} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")

def grp(gid, name, children, path=None):
    parts = [f"\t\t{gid} /* {name} */ = {{isa = PBXGroup; children = ({', '.join(children)}); "]
    if path:
        parts.append(f"path = {path}; ")
    parts.append('sourceTree = "<group>"; };')
    w("".join(parts))

# Flat groups for simplicity (low complexity)
swift_refs = [f"{refs[f]} /* {os.path.basename(f)} */" for f in files if f.endswith(".swift")]
res_refs = [f"{refs[f]} /* {os.path.basename(f)} */" for f in files if not f.endswith(".swift")]

grp(G["app"], APP, swift_refs + res_refs, APP)
grp(G["root"], "Root", [G["app"], G["products"]])

w(f"\t\t{G['sources']} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({', '.join(f'{bfiles[f]} /* {os.path.basename(f)} in Sources */' for f in files if f.endswith('.swift'))}); runOnlyForDeploymentPostprocessing = 0; }};")
w(f"\t\t{G['resphase']} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")

w(f"\t\t{G['target']} /* {APP} */ = {{isa = PBXNativeTarget; buildConfigurationList = {G['tcfglist']}; buildPhases = ({G['sources']}, {G['frameworks']}, {G['resphase']}); buildRules = (); dependencies = (); name = {APP}; productName = {APP}; productReference = {G['products']}; productType = \"com.apple.product-type.application\"; }};")

w(f"\t\t{G['project']} /* Project */ = {{isa = PBXProject; attributes = {{LastUpgradeCheck = 1500; BuildIndependentTargetsInParallel = 1; }}; buildConfigurationList = {G['cfglist']}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {G['root']}; productRefGroup = {G['products']}; projectDirPath = \"\"; projectRoot = \"\"; targets = ({G['target']}); }};")

for name, gid, cfgid in [("Debug", G["debug"], G["debug"]), ("Release", G["release"], G["release"])]:
    w(f"\t\t{gid} /* {name} */ = {{isa = XCBuildConfiguration; buildSettings = {{ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; DEVELOPMENT_TEAM = \"\"; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = {APP}/Info.plist; IPHONEOS_DEPLOYMENT_TARGET = 17.0; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\"); MARKETING_VERSION = 1.0; PRODUCT_BUNDLE_IDENTIFIER = com.glammeupp.studio; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; }}; name = {name}; }};")

w(f"\t\t{G['cfglist']} /* Build configuration list for PBXProject */ = {{isa = XCConfigurationList; buildConfigurations = ({G['debug']}, {G['release']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
w(f"\t\t{G['tcfglist']} /* Build configuration list for PBXNativeTarget */ = {{isa = XCConfigurationList; buildConfigurations = ({G['debug']}, {G['release']}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")

w("\t};")
w(f"\trootObject = {G['project']} /* Project */;")
w("}")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    f.write("\n".join(L))
print(f"Wrote {OUT} ({len(files)} files)")
