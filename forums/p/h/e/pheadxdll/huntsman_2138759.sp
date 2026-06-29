#include <sourcemod>

#define PLUGIN_VERSION "0.2"
#define FILE_GAMEDATA "huntsman.plugin"

new Handle:g_hCvarEnabled;

new Address:g_addrPatch = Address_Null;
new g_iPayload;

new g_iMemoryPatched = 0;

public Plugin:myinfo = 
{
	name = "Fire huntsman in the air",
	author = "linux_lover",
	description = "Allows snipers to fire their bow while in jump.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2070774"
}

public OnPluginStart()
{
	Patch_Init();

	g_hCvarEnabled = CreateConVar("huntsman_enabled", "1", "0/1 - Enable or disable this plugin's functionality.");
	CreateConVar("huntsman_version", PLUGIN_VERSION, "Huntsman Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookConVarChange(g_hCvarEnabled, CVarChanged_Enabled);
}

public OnConfigsExecuted()
{
	if(GetConVarBool(g_hCvarEnabled))
	{
		Patch_Enable();
	}
}

public CVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarBool(g_hCvarEnabled))
	{
		Patch_Enable();
	}else{
		Patch_Disable();
	}
}

public OnPluginEnd()
{
	Patch_Disable();
}

Patch_Init()
{
	g_addrPatch = Address_Null;
	g_iPayload = -1;
	g_iMemoryPatched = 0;
	
	// The "tf" in the gamedata probably makes game check redundant
	decl String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));
	if(strcmp(strGame, "tf") != 0)
	{
		LogMessage("Failed to load: Can only be loaded on Team Fortress.");
		return;
	}
	
	new Handle:hGamedata = LoadGameConfigFile(FILE_GAMEDATA);
	if(hGamedata == INVALID_HANDLE)
	{
		LogMessage("Failed to load: Missing gamedata/%s.txt.", FILE_GAMEDATA);
		return;
	}
	
	new iPatchOffset = GameConfGetOffset(hGamedata, "Offset_HuntsmanPatch");
	if(iPatchOffset == -1)
	{
		LogMessage("Failed to load: Failed to find Offset_HuntsmanPatch.");
		CloseHandle(hGamedata);
		return;
	}
	
	new iPayload = GameConfGetOffset(hGamedata, "Payload_HuntsmanPatch");
	if(iPayload == -1)
	{
		LogMessage("Failed to load: Failed to find Payload_HuntsmanPatch.");
		CloseHandle(hGamedata);
		return;
	}
	
	g_addrPatch = GameConfGetAddress(hGamedata, "HuntsmanPatch");
	if(g_addrPatch == Address_Null)
	{
		LogMessage("Failed to load: Failed to find HuntsmanPatch.");
		CloseHandle(hGamedata);
		return;
	}
	
	CloseHandle(hGamedata);
	
	g_addrPatch += Address:iPatchOffset;
	g_iPayload = iPayload;
}

Patch_Enable()
{
	if(g_addrPatch == Address_Null) return;
	if(g_iPayload == -1) return;

	if(g_iMemoryPatched != 0) return;

	LogMessage("Patching at address: 0x%.8X..", g_addrPatch);
	g_iMemoryPatched = LoadFromAddress(g_addrPatch, NumberType_Int8);
	StoreToAddress(g_addrPatch, g_iPayload, NumberType_Int8);
}

Patch_Disable()
{
	if(g_addrPatch == Address_Null) return;
	if(g_iPayload == -1) return;

	if(g_iMemoryPatched <= 0) return;
	
	LogMessage("Unpatching at address: 0x%.8X..", g_addrPatch);
	StoreToAddress(g_addrPatch, g_iMemoryPatched, NumberType_Int8);
	
	g_iMemoryPatched = 0;
}