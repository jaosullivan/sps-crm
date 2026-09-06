#!/usr/bin/env python3
"""Generate SPSCRM.xcodeproj/project.pbxproj from the on-disk Swift tree."""

from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "SPSCRM"
TESTS = ROOT / "SPSCRMTests"
PROJ = ROOT / "SPSCRM.xcodeproj"


def hid(label: str) -> str:
    digest = hashlib.sha1(label.encode()).hexdigest().upper()
    return digest[:24]


def collect_swift(folder: Path) -> list[Path]:
    return sorted(p.relative_to(ROOT) for p in folder.rglob("*.swift"))


def main() -> None:
    app_swift = collect_swift(APP)
    test_swift = collect_swift(TESTS)
    assets = Path("SPSCRM/Assets.xcassets")
    settings_bundle = Path("SPSCRM/Settings.bundle")
    info_plist = Path("SPSCRM/Info.plist")

    ids = {
        "project": hid("project"),
        "app_target": hid("app_target"),
        "test_target": hid("test_target"),
        "app_config_list": hid("app_config_list"),
        "test_config_list": hid("test_config_list"),
        "proj_config_list": hid("proj_config_list"),
        "app_debug": hid("app_debug"),
        "app_release": hid("app_release"),
        "test_debug": hid("test_debug"),
        "test_release": hid("test_release"),
        "proj_debug": hid("proj_debug"),
        "proj_release": hid("proj_release"),
        "sources_phase": hid("sources_phase"),
        "resources_phase": hid("resources_phase"),
        "frameworks_phase": hid("frameworks_phase"),
        "test_sources_phase": hid("test_sources_phase"),
        "test_frameworks_phase": hid("test_frameworks_phase"),
        "main_group": hid("main_group"),
        "app_group": hid("app_group"),
        "test_group": hid("test_group"),
        "products_group": hid("products_group"),
        "app_product": hid("app_product"),
        "test_product": hid("test_product"),
        "assets_ref": hid("assets_ref"),
        "assets_build": hid("assets_build"),
        "settings_ref": hid("settings_ref"),
        "settings_build": hid("settings_build"),
        "plist_ref": hid("plist_ref"),
        "container": hid("container"),
        "dep": hid("dep"),
    }

    file_refs: dict[Path, str] = {}
    build_files: dict[Path, str] = {}
    for path in app_swift + test_swift:
        file_refs[path] = hid(f"ref:{path}")
        build_files[path] = hid(f"build:{path}")

    def fileref_entries() -> str:
        lines = []
        for path in app_swift + test_swift:
            lines.append(
                f"\t\t{file_refs[path]} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {path.name}; sourceTree = \"<group>\"; }};"
            )
        lines.append(
            f"\t\t{ids['assets_ref']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};"
        )
        lines.append(
            f"\t\t{ids['settings_ref']} /* Settings.bundle */ = {{isa = PBXFileReference; lastKnownFileType = \"wrapper.plug-in\"; path = Settings.bundle; sourceTree = \"<group>\"; }};"
        )
        lines.append(
            f"\t\t{ids['plist_ref']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};"
        )
        lines.append(
            f"\t\t{ids['app_product']} /* SPSCRM.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SPSCRM.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
        )
        lines.append(
            f"\t\t{ids['test_product']} /* SPSCRMTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SPSCRMTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
        )
        return "\n".join(lines)

    def buildfile_entries() -> str:
        lines = []
        for path in app_swift:
            lines.append(
                f"\t\t{build_files[path]} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};"
            )
        for path in test_swift:
            lines.append(
                f"\t\t{build_files[path]} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};"
            )
        lines.append(
            f"\t\t{ids['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['assets_ref']} /* Assets.xcassets */; }};"
        )
        lines.append(
            f"\t\t{ids['settings_build']} /* Settings.bundle in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['settings_ref']} /* Settings.bundle */; }};"
        )
        return "\n".join(lines)

    # Nested groups under SPSCRM matching folders
    groups: dict[str, list[str]] = {}
    group_ids: dict[str, str] = {"": ids["app_group"]}

    def ensure_group(rel: str) -> str:
        if rel in group_ids:
            return group_ids[rel]
        gid = hid(f"group:{rel}")
        group_ids[rel] = gid
        parent = str(Path(rel).parent) if Path(rel).parent.as_posix() != "." else ""
        ensure_group(parent)
        groups.setdefault(parent, []).append(f"folder:{rel}")
        return gid

    children_by_group: dict[str, list[str]] = {"": []}
    app_rel = Path("SPSCRM")
    for path in app_swift:
        parent_path = path.parent.relative_to(app_rel)
        parent = "" if parent_path.as_posix() == "." else parent_path.as_posix()
        if parent:
            ensure_group(parent)
        children_by_group.setdefault(parent, []).append(f"file:{path}")

    children_by_group.setdefault("", []).extend(["assets", "settings", "plist"])

    def group_children_lines(key: str) -> str:
        items = []
        # folders first
        for child in sorted(group_ids):
            if child and str(Path(child).parent) == (key if key else "."):
                # Path('.').parent is also '.' — handle root
                parent = "" if Path(child).parent.as_posix() in {".", ""} else Path(child).parent.as_posix()
                if parent != key:
                    continue
                name = Path(child).name
                items.append(f"\t\t\t\t{group_ids[child]} /* {name} */,")
        for token in children_by_group.get(key, []):
            if token.startswith("file:"):
                path = Path(token[5:])
                items.append(f"\t\t\t\t{file_refs[path]} /* {path.name} */,")
            elif token == "assets":
                items.append(f"\t\t\t\t{ids['assets_ref']} /* Assets.xcassets */,")
            elif token == "settings":
                items.append(f"\t\t\t\t{ids['settings_ref']} /* Settings.bundle */,")
            elif token == "plist":
                items.append(f"\t\t\t\t{ids['plist_ref']} /* Info.plist */,")
        return "\n".join(items)

    group_sections = []
    for key, gid in sorted(group_ids.items(), key=lambda kv: kv[0]):
        name = "SPSCRM" if key == "" else Path(key).name
        path_line = "\t\t\tpath = SPSCRM;\n" if key == "" else f"\t\t\tpath = {Path(key).name};\n"
        group_sections.append(
            f"\t\t{gid} /* {name} */ = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n"
            f"{group_children_lines(key)}\n"
            f"\t\t\t);\n"
            f"{path_line}"
            f"\t\t\tsourceTree = \"<group>\";\n"
            f"\t\t}};"
        )

    test_children = "\n".join(
        f"\t\t\t\t{file_refs[p]} /* {p.name} */," for p in test_swift
    )

    app_source_builds = "\n".join(
        f"\t\t\t\t{build_files[p]} /* {p.name} in Sources */," for p in app_swift
    )
    test_source_builds = "\n".join(
        f"\t\t\t\t{build_files[p]} /* {p.name} in Sources */," for p in test_swift
    )

    common_debug = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.9;
"""
    common_release = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.9;
				VALIDATE_PRODUCT = YES;
"""

    target_settings = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = SPSCRM/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "SPS CRM";
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.stpatrickshk.spscrm;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = targeted;
				TARGETED_DEVICE_FAMILY = 1;
"""

    test_settings = """
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.stpatrickshk.spscrm.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_STRICT_CONCURRENCY = targeted;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/SPSCRM.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SPSCRM";
"""

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{buildfile_entries()}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{ids['container']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {ids['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {ids['app_target']};
			remoteInfo = SPSCRM;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
{fileref_entries()}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{ids['frameworks_phase']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['test_frameworks_phase']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{ids['main_group']} = {{
			isa = PBXGroup;
			children = (
				{ids['app_group']} /* SPSCRM */,
				{ids['test_group']} /* SPSCRMTests */,
				{ids['products_group']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{ids['products_group']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{ids['app_product']} /* SPSCRM.app */,
				{ids['test_product']} /* SPSCRMTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{ids['test_group']} /* SPSCRMTests */ = {{
			isa = PBXGroup;
			children = (
{test_children}
			);
			path = SPSCRMTests;
			sourceTree = "<group>";
		}};
{chr(10).join(group_sections)}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{ids['app_target']} /* SPSCRM */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['app_config_list']} /* Build configuration list for PBXNativeTarget "SPSCRM" */;
			buildPhases = (
				{ids['sources_phase']} /* Sources */,
				{ids['frameworks_phase']} /* Frameworks */,
				{ids['resources_phase']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = SPSCRM;
			productName = SPSCRM;
			productReference = {ids['app_product']} /* SPSCRM.app */;
			productType = "com.apple.product-type.application";
		}};
		{ids['test_target']} /* SPSCRMTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['test_config_list']} /* Build configuration list for PBXNativeTarget "SPSCRMTests" */;
			buildPhases = (
				{ids['test_sources_phase']} /* Sources */,
				{ids['test_frameworks_phase']} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				{ids['dep']} /* PBXTargetDependency */,
			);
			name = SPSCRMTests;
			productName = SPSCRMTests;
			productReference = {ids['test_product']} /* SPSCRMTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{ids['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{ids['app_target']} = {{
						CreatedOnToolsVersion = 15.0;
					}};
					{ids['test_target']} = {{
						CreatedOnToolsVersion = 15.0;
						TestTargetID = {ids['app_target']};
					}};
				}};
			}};
			buildConfigurationList = {ids['proj_config_list']} /* Build configuration list for PBXProject "SPSCRM" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {ids['main_group']};
			productRefGroup = {ids['products_group']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{ids['app_target']} /* SPSCRM */,
				{ids['test_target']} /* SPSCRMTests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{ids['resources_phase']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{ids['assets_build']} /* Assets.xcassets in Resources */,
				{ids['settings_build']} /* Settings.bundle in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{ids['sources_phase']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{app_source_builds}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['test_sources_phase']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{test_source_builds}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{ids['dep']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {ids['app_target']} /* SPSCRM */;
			targetProxy = {ids['container']} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{ids['proj_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_debug}
			}};
			name = Debug;
		}};
		{ids['proj_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_release}
			}};
			name = Release;
		}};
		{ids['app_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{target_settings}
			}};
			name = Debug;
		}};
		{ids['app_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{target_settings}
			}};
			name = Release;
		}};
		{ids['test_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{test_settings}
			}};
			name = Debug;
		}};
		{ids['test_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{test_settings}
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{ids['proj_config_list']} /* Build configuration list for PBXProject "SPSCRM" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['proj_debug']} /* Debug */,
				{ids['proj_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['app_config_list']} /* Build configuration list for PBXNativeTarget "SPSCRM" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['app_debug']} /* Debug */,
				{ids['app_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['test_config_list']} /* Build configuration list for PBXNativeTarget "SPSCRMTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['test_debug']} /* Debug */,
				{ids['test_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {ids['project']} /* Project object */;
}}
"""

    PROJ.mkdir(parents=True, exist_ok=True)
    (PROJ / "project.pbxproj").write_text(pbx)
    scheme_dir = PROJ / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "SPSCRM.xcscheme").write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['app_target']}"
               BuildableName = "SPSCRM.app"
               BlueprintName = "SPSCRM"
               ReferencedContainer = "container:SPSCRM.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['test_target']}"
               BuildableName = "SPSCRMTests.xctest"
               BlueprintName = "SPSCRMTests"
               ReferencedContainer = "container:SPSCRM.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['app_target']}"
            BuildableName = "SPSCRM.app"
            BlueprintName = "SPSCRM"
            ReferencedContainer = "container:SPSCRM.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['app_target']}"
            BuildableName = "SPSCRM.app"
            BlueprintName = "SPSCRM"
            ReferencedContainer = "container:SPSCRM.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    )
    print(f"Wrote {PROJ / 'project.pbxproj'} ({len(app_swift)} app sources, {len(test_swift)} tests)")


if __name__ == "__main__":
    main()
