#define PLUGIN_NAME "Spells"
#define PLUGIN_AUTHOR "pear"
#define PLUGIN_VERSION "1.1"

#pragma semicolon 1

#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo =  {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	version = PLUGIN_VERSION
}

#define PAGE_LENGTH 7

char sSpells[][] =  {
	"Fireball",
	"Blast Jump",
};

ConVar hCooldown, hCooldownRare;
float fSpellDelay, fSpellDelayRare, fTimeFired[MAXPLAYERS + 1], fTimeFiredRare[MAXPLAYERS + 1];

public void OnPluginStart() {
	if (GetEngineVersion() != Engine_TF2)SetFailState("[%s] Plugin only works with TF2!", PLUGIN_NAME);
	
	CreateConVar("sm_spells_version", PLUGIN_VERSION);
	hCooldown = CreateConVar("sm_spells_cooldown", "0", "Spell usage cooldown");
	hCooldownRare = CreateConVar("sm_spells_cooldown_rare", "0", "Rare spell usage cooldown (Added on top of normal cooldown)");
	hCooldown.AddChangeHook(OnConVarChanged);
	hCooldownRare.AddChangeHook(OnConVarChanged);
	fSpellDelay = hCooldown.FloatValue;
	fSpellDelayRare = hCooldownRare.FloatValue;
	
	RegAdminCmd("sm_spells", OnCommand, ADMFLAG_GENERIC, "sm_spells [index]");
	RegAdminCmd("sm_spell", OnCommand, ADMFLAG_GENERIC, "sm_spell [index]");
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	if (convar == hCooldown)fSpellDelay = StringToFloat(newValue);
	else if (convar == hCooldownRare)fSpellDelayRare = StringToFloat(newValue);
}

public Action OnCommand(int client, int args) {
	if (!client)ReplyToCommand(client, "[SM] Command only available in-game.");
	else if (!args)SpellMenu(client, 0);
	else {
		char arg[4]; GetCmdArg(1, arg, sizeof(arg));
		int value, n = StringToIntEx(arg, value);
		if (value >= 0 && value < sizeof(sSpells) && strlen(arg) == n)CastSpell(client, value);
		else ReplyToCommand(client, "[SM] Invalid spell index!");
	}
	return Plugin_Handled;
}

public void SpellMenu(int client, int index) {
	Menu menu = new Menu(OnMenu);
	menu.SetTitle("Spells");
	for (int i = 0; i < sizeof(sSpells); i++) {
		char id[4]; IntToString(i, id, sizeof(id));
		menu.AddItem(id, sSpells[i]);
	}
	menu.ExitButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int OnMenu(Menu menu, MenuAction action, int client, int item) {
	switch (action) {
		case MenuAction_Select: {
			char id[4]; GetMenuItem(menu, item, id, sizeof(id));
			int value = StringToInt(id);
			bool rare = (value >= PAGE_LENGTH);
			
			CastSpell(client, value);
			
			if ((fSpellDelay + (rare ? fSpellDelayRare : 0.0)) <= 0)SpellMenu(client, rare ? PAGE_LENGTH : 0);
		}
		case MenuAction_End:delete menu;
	}
	return 0;
}

public void CastSpell(int client, int index) {
	float time = GetGameTime();
	bool rare = (index >= PAGE_LENGTH);
	float delay = fTimeFired[client] - time + fSpellDelay;
	if (rare) {
		float actual = fTimeFiredRare[client] - time + fSpellDelay + fSpellDelayRare;
		if (actual > 0)delay = actual;
	}
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
			
			if (rare)fTimeFiredRare[client] = time;
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
