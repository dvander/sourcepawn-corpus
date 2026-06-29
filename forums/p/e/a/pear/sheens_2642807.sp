#define PLUGIN_NAME "Sheens"
#define PLUGIN_AUTHOR "pear"
#define PLUGIN_VERSION "1.2.1"

#pragma semicolon 1

#include <sdktools>

#pragma newdecls required

public Plugin myinfo =  {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	version = PLUGIN_VERSION
}

#define KS_SHEEN 'S'
#define KS_EFFECT 'E'
#define KS_BOTH 'B'

ConVar cSheensAccess;
int iSheensAccess;

char sSheens[][] =  {
	"Team Shine", 
	"Deadly Daffodil", 
	"Manndarin", 
	"Mean Green", 
	"Agonizing Emerald", 
	"Villainous Violet", 
	"Hot Rod"
};

char sEffects[][] =  {
	"Fire Horns", 
	"Cerebral Discharge", 
	"Tornado", 
	"Flames", 
	"Singularity", 
	"Incinerator", 
	"Hypno-Beam"
};

enum struct Handles {
	Handle GetAttributeDefinition;
	Handle ItemSchema;
	Handle SetRuntimeAttributeValue;
	Handle GetAttributeByID;
	Handle RemoveAttribute;
	
	void load(char[] config) {
		Handle cfg = LoadGameConfigFile(config);
		
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CEconItemSchema::GetAttributeDefinition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		this.GetAttributeDefinition = EndPrepSDKCall();
		
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "GEconItemSchema");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		this.ItemSchema = EndPrepSDKCall();
		
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CAttributeList::SetRuntimeAttributeValue");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		this.SetRuntimeAttributeValue = EndPrepSDKCall();
		
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CAttributeList::GetAttributeByID");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		this.GetAttributeByID = EndPrepSDKCall();
		
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CAttributeList::RemoveAttribute");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		this.RemoveAttribute = EndPrepSDKCall();
	}
}

Handles SDK;

methodmap Attributes {
	public static bool IsValidAddress(Address addr) {
		return (addr & view_as<Address>(0x7FFFFFFF)) >= view_as<Address>(0x10000);
	}
	public static bool Set(int entity, int index, float value) {
		int offs = GetEntSendPropOffs(entity, "m_AttributeList", true);
		if (offs > 0) {
			Address attrib = SDKCall(SDK.GetAttributeDefinition, SDKCall(SDK.ItemSchema), index);
			if (Attributes.IsValidAddress(attrib)) {
				SDKCall(SDK.SetRuntimeAttributeValue, GetEntityAddress(entity) + view_as<Address>(offs), attrib, value);
				return true;
			}
		}
		return false;
	}
	public static float Get(int entity, int index) {
		int offs = GetEntSendPropOffs(entity, "m_AttributeList", true);
		if (offs > 0) {
			Address attrib = view_as<Address>(SDKCall(SDK.GetAttributeByID, GetEntityAddress(entity) + view_as<Address>(offs), index));
			if (Attributes.IsValidAddress(attrib)) {
				return view_as<float>(LoadFromAddress(attrib + view_as<Address>(8), NumberType_Int32));
			}
		}
		return 0.0;
	}
	public static bool Remove(int entity, int index) {
		int offs = GetEntSendPropOffs(entity, "m_AttributeList", true);
		if (offs > 0) {
			Address attrib = SDKCall(SDK.GetAttributeDefinition, SDKCall(SDK.ItemSchema), index);
			if (Attributes.IsValidAddress(attrib)) {
				SDKCall(SDK.RemoveAttribute, GetEntityAddress(entity) + view_as<Address>(offs), attrib);
				return true;
			}
		}
		return false;
	}
}

methodmap SheensMenu < Menu {
	public SheensMenu(MenuHandler handler) {
		return view_as<SheensMenu>(new Menu(handler));
	}
	public void AddItemArray(char[][] arr, int size) {
		for (int i = 0; i < size; i++) {
			char info[8]; IntToString(i, info, sizeof(info));
			this.AddItem(info, arr[i]);
		}
	}
	public void Show(int client, char type, char[] data = "") {
		char buf[8]; Format(buf, sizeof(buf), "%s", type);
		this.AddItem(buf, "TYPE", ITEMDRAW_IGNORE);
		this.AddItem(data, "DATA", ITEMDRAW_IGNORE);
		switch (type) {
			case KS_SHEEN, KS_BOTH: {
				this.SetTitle("Select Killstreak Sheen");
				this.AddItemArray(sSheens, sizeof(sSheens));
				this.ExitBackButton = true;
			}
			case KS_EFFECT: {
				this.SetTitle("Select Killstreak Effect");
				this.AddItemArray(sEffects, sizeof(sEffects));
				this.ExitBackButton = true;
			}
			default: {
				this.SetTitle("Select Killstreak Type");
				this.AddItem("1", "Off");
				this.AddItem("2", "Normal");
				this.AddItem("3", "Specialized");
				this.AddItem("4", "Professional");
			}
		}
		
		this.ExitButton = true;
		this.Display(client, MENU_TIME_FOREVER);
	}
}

public void OnPluginStart() {
	if (GetEngineVersion() != Engine_TF2)SetFailState("[Sheens] Only available for TF2.");
	
	RegConsoleCmd("sm_sheens", OnCommand, "sm_sheens [sheen] [effect]");
	RegConsoleCmd("sm_sheen", OnCommand, "sm_sheen [sheen] [effect]");
	
	CreateConVar("sm_sheens_version", PLUGIN_VERSION, "Sheens Plugin Version", FCVAR_NOTIFY);
	
	cSheensAccess = CreateConVar("sm_sheens_flag", "k", "Sheens Access Flag");
	cSheensAccess.AddChangeHook(OnConVarChanged);
	
	SDK.load("tf2.attributes");
	LoadTranslations("sheens.phrases");
}

public void OnConfigsExecuted() {
	char flag[8]; GetConVarString(cSheensAccess, flag, sizeof(flag));
	iSheensAccess = ReadFlagString(flag);
}

public void OnConVarChanged(ConVar conVar, char[] oldValue, char[] newValue) {
	if (conVar == cSheensAccess)iSheensAccess = ReadFlagString(newValue);
}

public Action OnCommand(int client, int args) {
	if (!client)PrintToServer("[%s] %t", PLUGIN_NAME, "in-game only");
	else if (!CheckCommandAccess(client, "sm_sheens_flag", iSheensAccess))ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "no access");
	else if (!args)ShowSheensMenu(client);
	else {
		char arg1[8], arg2[8];
		int sheen, effect;
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		if (strlen(arg1) != StringToIntEx(arg1, sheen))sheen = -3;
		if (strlen(arg2) != StringToIntEx(arg2, effect) || effect < 0)effect = -3;
		ApplySheens(client, arg1[0] ? sheen - 1 : -3, arg2[0] ? effect - 1 : -1);
	}
	return Plugin_Handled;
}

void ApplySheens(int client, int sheen = -1, int effect = -1) {
	if (!IsPlayerAlive(client))ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "player must be alive");
	else {
		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (!IsValidEntity(weapon))ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "invalid weapon");
		else if (sheen < -2 || sheen >= sizeof(sSheens))ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "invalid sheen");
		else if (effect < -2 || effect >= sizeof(sEffects))ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "invalid effect");
		else {
			if (sheen == -2) {
				Attributes.Remove(weapon, 2013);
				Attributes.Remove(weapon, 2014);
				Attributes.Remove(weapon, 2025);
				ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "disabled killstreak");
			}
			else if (sheen == -1) {
				Attributes.Remove(weapon, 2013);
				Attributes.Remove(weapon, 2014);
				Attributes.Set(weapon, 2025, 1.0);
				ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "enabled killstreak");
			}
			else if (effect >= 0) {
				Attributes.Set(weapon, 2013, float(effect + 2002));
				Attributes.Set(weapon, 2014, float(sheen + 1));
				Attributes.Set(weapon, 2025, 3.0);
				ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "set sheen to x and effect to y", sSheens[sheen], sEffects[effect]);
			}
			else {
				Attributes.Remove(weapon, 2013);
				Attributes.Set(weapon, 2014, float(sheen + 1));
				Attributes.Set(weapon, 2025, 2.0);
				ReplyToCommand(client, "[%s] %t", PLUGIN_NAME, "set sheen to x", sSheens[sheen]);
			}
		}
	}
}

void ShowSheensMenu(int client, char type = 0, char[] data = "") {
	SheensMenu menu = new SheensMenu(OnSheensMenu);
	menu.Show(client, type, data);
}

public int OnSheensMenu(Menu menu, MenuAction action, int param1, int param2) {
	char type[8]; menu.GetItem(0, type, sizeof(type));
	char data[8]; menu.GetItem(1, data, sizeof(data));
	char info[8]; menu.GetItem(param2, info, sizeof(info));
	switch (action) {
		case MenuAction_Select: {
			switch (type[0]) {
				case KS_SHEEN, KS_BOTH: {
					if (type[0] == KS_BOTH)ShowSheensMenu(param1, KS_EFFECT, info);
					else ApplySheens(param1, StringToInt(info));
				}
				case KS_EFFECT: {
					ApplySheens(param1, StringToInt(data), StringToInt(info));
				}
				default: {
					switch (StringToInt(info) - 1) {
						case 0:ApplySheens(param1, -2);
						case 1:ApplySheens(param1, -1);
						case 2:ShowSheensMenu(param1, KS_SHEEN);
						case 3:ShowSheensMenu(param1, KS_BOTH);
					}
				}
			}
		}
		case MenuAction_Cancel: {
			switch (type[0]) {
				case KS_BOTH, KS_SHEEN:ShowSheensMenu(param1);
				case KS_EFFECT:ShowSheensMenu(param1, KS_BOTH);
			}
		}
		case MenuAction_End:delete menu;
	}
	return 0;
} 