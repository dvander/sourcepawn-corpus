#define PLUGIN_NAME "Spells"
#define PLUGIN_AUTHOR "pear"
#define PLUGIN_VERSION "1.1-ph"

#pragma semicolon 1

#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo =  {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	version = PLUGIN_VERSION
}

char sSpells[][] =  {
	"Fireball", 
	"Swarm of Bats", 
	"", 
	"", 
	"Blast Jump"
};

ConVar hCooldown;
float fSpellDelay, fTimeFired[MAXPLAYERS + 1];

public void OnPluginStart() {
	if (GetEngineVersion() != Engine_TF2)SetFailState("[%s] Plugin only works with TF2!", PLUGIN_NAME);
	
	CreateConVar("sm_spells_version", PLUGIN_VERSION);
	hCooldown = CreateConVar("sm_spells_cooldown", "0", "Spell usage cooldown");
	hCooldown.AddChangeHook(OnConVarChanged);
	fSpellDelay = hCooldown.FloatValue;
	
	RegAdminCmd("sm_spells", OnCommand, ADMFLAG_GENERIC, "sm_spells [index]");
	RegAdminCmd("sm_spell", OnCommand, ADMFLAG_GENERIC, "sm_spell [index]");
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	if (convar == hCooldown)fSpellDelay = StringToFloat(newValue);
}

public Action OnCommand(int client, int args) {
	if (!client)ReplyToCommand(client, "[SM] Command only available in-game.");
	else if (!args)SpellMenu(client);
	else {
		char arg[4]; GetCmdArg(1, arg, sizeof(arg));
		int value, n = StringToIntEx(arg, value);
		if (value >= 0 && value < sizeof(sSpells) && strlen(arg) == n && sSpells[value][0])CastSpell(client, value);
		else ReplyToCommand(client, "[SM] Invalid spell index!");
	}
	return Plugin_Handled;
}

public void SpellMenu(int client) {
	Menu menu = new Menu(OnMenu);
	menu.SetTitle("Spells");
	for (int i = 0; i < sizeof(sSpells); i++) {
		if (!sSpells[i][0])continue;
		char id[4]; IntToString(i, id, sizeof(id));
		menu.AddItem(id, sSpells[i]);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int OnMenu(Menu menu, MenuAction action, int client, int item) {
	switch (action) {
		case MenuAction_Select: {
			char id[4]; GetMenuItem(menu, item, id, sizeof(id));
			int value = StringToInt(id);
			
			CastSpell(client, value);
			
			if (fSpellDelay <= 0)SpellMenu(client);
		}
		case MenuAction_End:delete menu;
	}
	return 0;
}

public void CastSpell(int client, int index) {
	float time = GetGameTime();
	float delay = fTimeFired[client] - time + fSpellDelay;
	if (delay > 0)ReplyToCommand(client, "[SM] Please wait %.2f seconds before casting the next spell.", delay);
	else if (!IsPlayerAlive(client))ReplyToCommand(client, "[SM] You must be alive to use this command!");
	else {
		int ent = FindSpellbook(client);
		if (!ent) {
			ent = CreateEntityByName("tf_weapon_spellbook");
			if (ent != -1) {
				SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", 1132);
				SetEntProp(ent, Prop_Send, "m_bInitialized", 1);
				SetEntProp(ent, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
				DispatchSpawn(ent);
			}
			else {
				ReplyToCommand(client, "[SM] Could not create spellbook entity!");
				return;
			}
		}
		
		int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (active != ent) {
			SetEntProp(ent, Prop_Send, "m_iSpellCharges", 1);
			SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", index);
			
			SetEntPropEnt(client, Prop_Send, "m_hLastWeapon", active);
			EquipPlayerWeapon(client, ent);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", ent);
			
			fTimeFired[client] = time;
		}
	}
}

public int FindSpellbook(int client) {
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1) {
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))return i;
	}
	return 0;
}
