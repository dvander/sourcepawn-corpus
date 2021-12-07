#include <sourcemod>
#include <mempatch>

new Handle:clientsettings;
new Handle:desc;
new Handle:hostageuse;
new Handle:m60drop;
new Handle:spread;

public Plugin:myinfo = 
{
	name = "MemPatch",
	author = "Dr!fter",
	description = "Mem patch test",
	version = "1.0.0"
}
public OnPluginStart()
{
	decl String:descname[32];
	GetGameDescription(descname, sizeof(descname), true);
	decl String:name[32];
	GetGameFolderName(name, sizeof(name));
	new Handle:gameconf = LoadGameConfigFile("mempatchtest.games");
	if(strcmp(name, "cstrike") == 0)
	{
		clientsettings = SetupMemoryPatchBytes(gameconf, "ClientSettings", "ClientSettingsOffset", "ClientSettingsPatch");
		new String:buffer[((4*4)+1)];//This should be ((number of bytes to read * 4) +1)
		ReadMemoryBytes(gameconf, "ClientSettings", "ClientSettingsOffset", 4, buffer, sizeof(buffer));
		PrintToServer("The bytes before patch read are %s", buffer);
		MemoryPatchBytes(clientsettings);
		ReadMemoryBytes(gameconf, "ClientSettings", "ClientSettingsOffset", 4, buffer, sizeof(buffer));
		PrintToServer("The bytes after patch read are %s", buffer);
		
		desc = SetupMemoryPatchString(gameconf, "DescriptionName", "", strlen(descname)+1);
		new String:temp[strlen(descname)+1];
		ReadMemoryString(desc, temp, strlen(descname)+1);
		PrintToServer("The current description is %s", temp);
		MemoryPatchString(desc, "I Like Cookies");
		ReadMemoryString(desc, temp, strlen(descname)+1);
		PrintToServer("Patched description is %s", temp);
		
		hostageuse = SetupMemoryPatchInt(gameconf, "GivesCtUseBonus", "GivesCtUseBonusOffset", MEM_PATCH_UINT16);
		PrintToServer("Current hostage money reward is %i", ReadMemoryInt(hostageuse));
		MemoryPatchInt(hostageuse, 800);
		PrintToServer("New hostage money reward is %i", ReadMemoryInt(hostageuse));
		
		spread = SetupMemoryPatchFloat(gameconf, "M3Spread", "");
		PrintToServer("Current M3 spread is %f", ReadMemoryFloat(spread));
		MemoryPatchFloat(spread, 0.0);
		PrintToServer("New M3 spread is %f", ReadMemoryFloat(spread));
	}
	else if(strcmp(name, "left4dead2") == 0)
	{
		m60drop = SetupMemoryPatchBytes(gameconf, "M60PrimaryAttack", "M60PrimaryAttackOffset", "M60PrimaryAttackPatch");
		new String:buffer[((4*4)+1)];//This should be ((number of bytes to read * 4) +1)
		ReadMemoryBytes(gameconf, "M60PrimaryAttack", "M60PrimaryAttackOffset", 4, buffer, sizeof(buffer));
		PrintToServer("The bytes before patch read are %s", buffer);
		MemoryPatchBytes(m60drop);
		ReadMemoryBytes(gameconf, "M60PrimaryAttack", "M60PrimaryAttackOffset", 4, buffer, sizeof(buffer));
		PrintToServer("The bytes after patch read are %s", buffer);
		
		
		desc = SetupMemoryPatchString(gameconf, "DescriptionName", "", strlen(descname)+1);
		new String:temp[strlen(descname)+1];
		ReadMemoryString(desc, temp, strlen(descname)+1);
		PrintToServer("The current description is %s", temp);
		MemoryPatchString(desc, "Left 4 Dead 2");
		ReadMemoryString(desc, temp, strlen(descname)+1);
		PrintToServer("Patched description is %s", temp);
	}
	CloseHandle(gameconf);
}
public OnPluginEnd()
{
	decl String:name[32];
	GetGameFolderName(name, sizeof(name));
	if(strcmp(name, "cstrike") == 0)
	{
		RestoreMemoryPatch(clientsettings);
		CloseHandle(clientsettings);
		RestoreMemoryPatch(desc);
		CloseHandle(desc);
		RestoreMemoryPatch(hostageuse);
		CloseHandle(hostageuse);
		RestoreMemoryPatch(spread);
		CloseHandle(spread);
	}
	else if(strcmp(name, "left4dead2") == 0)
	{
		RestoreMemoryPatch(m60drop);
		CloseHandle(m60drop);
		RestoreMemoryPatch(desc);
		CloseHandle(desc);
	}
}