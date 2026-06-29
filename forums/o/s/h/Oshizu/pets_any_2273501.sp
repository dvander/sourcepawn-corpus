#include <sdktools>
#include <sdkhooks>

#define NPCCOLOR "\x07FFFFFF"

#define SOUND_SPAWN "ambient/machines/catapult_throw.wav"

#define STATE_IDLE		1
#define STATE_WALKING	2
#define STATE_JUMPING	3

#define HEIGHT_GROUND	1
#define HEIGHT_HOVER	2
#define HEIGHT_FLY		3

#define PETCOLOR_NORMAL	0
#define PETCOLOR_RED	1
#define PETCOLOR_GREEN	2
#define PETCOLOR_BLUE	3
#define PETCOLOR_PINK	4
#define PETCOLOR_ORANGE	5
#define PETCOLOR_CYAN	6
#define PETCOLOR_LIME	7
#define PETCOLOR_BLACK	8
#define PETCOLOR_TEAM	9
#define PETCOLOR_LTEAM	10
#define PETCOLOR_DTEAM	11
#define PETCOLOR_MAGIC	12

#define PET_HUGCRAB		1

enum petContent
{
	String:iName[64],
	String:iDesc[64],
	String:iModel[128],
	String:iSoundGeneric[128],
	String:iSoundAmount[128],
	String:iSoundGeneric_2[128],
	String:iSoundGeneric_3[128],
	String:iSoundGeneric_4[128],
	String:iSoundGeneric_5[128],
	String:iSoundGeneric_6[128],
	String:iSoundGeneric_7[128],
	String:iSoundGeneric_8[128],
	String:iSoundGeneric_9[128],
	String:iSoundGeneric_10[128],
	
	String:iSkinName_1[64],
	String:iSkinName_2[64],
	String:iSkinName_3[64],
	String:iSkinName_4[64],
	String:iSkinName_5[64],
	String:iSkinName_6[64],
	String:iSkinName_7[64],
	String:iSkinName_8[64],
	String:iSkinName_9[64],
	String:iSkinName_10[64],
	
	String:iSoundJump[128],
	iPitch,
	String:iAnimIdle[64],
	String:iAnimWalk[64],
	String:iAnimJump[64],
	iHeight,
	iHeight_Custom,
	SkinID,
	SkinsAmount,
	ADMFLAG,
	CanBeColored,
	Hidden,
	Float:ModelScale
};

stock petInfo[256][petContent]

new pet[MAXPLAYERS+1];
new petType[MAXPLAYERS+1];
new String:petName[MAXPLAYERS+1][32];
new petColor[MAXPLAYERS+1];
new petHappiness[MAXPLAYERS+1];
new petParticle[MAXPLAYERS+1];
new petState[MAXPLAYERS+1];
new petSkin[MAXPLAYERS+1];
new bool:petChangeCooldown[MAXPLAYERS+1]

new LastIndex = 0;
new bool:MenuNotUsable = false;
new Handle:soundTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:MoodEnable = INVALID_HANDLE;
new Handle:PetCooldown = INVALID_HANDLE;
new Handle:Reload = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[TF2] SourcePets",
	author = "Oshizu & noodleboy347",
	description = "Get off me you",
	version = "1.18",
}

public TF2_OnWaitingForPlayersStart()
{
	MenuNotUsable = true;
}
 
public TF2_OnWaitingForPlayersEnd()
{
	MenuNotUsable = false; 
} 
 
stock CreateLoopingParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system"); 
	if (IsValidEdict(particle)) 
	{ 
		new String:tName[32]; 
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName)); 
		DispatchKeyValue(particle, "targetname", "tf2particle"); 
		DispatchKeyValue(particle, "parentname", tName); 
		DispatchKeyValue(particle, "effect_name", particleType); 
		DispatchSpawn(particle); 
		ActivateEntity(particle); 

		AcceptEntityInput(particle, "start"); 
    } 
	return particle; 
}
 
public OnPluginStart() 
{
	RegAdminCmd("sm_pets", PetsMenu, ADMFLAG_RESERVATION)
	RegAdminCmd("sm_petname", PetName, ADMFLAG_RESERVATION)
	RegAdminCmd("sm_petstatus", Command_Pet, ADMFLAG_RESERVATION)
	RegAdminCmd("sm_reloadpets", ReloadPets, ADMFLAG_ROOT)
	
	
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_death", Event_Death);
	
	CreateTimer(GetRandomFloat(28.0, 45.0), RandomizeMood, _, TIMER_REPEAT)
	
	CreateConVar("pets_version", "1.18", "- Do Not Touch!", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED)
	
	PetCooldown = CreateConVar("pets_change_cooldown", "4", "- Cooldown between changing your pet. Anything below 1 will result in no cooldown")
	MoodEnable = CreateConVar("pets_mood_enabled", "1", "- Should pets have various mood's by default?")
	Reload = CreateConVar("pets_reload_mapchange", "0", "- Should plugin attempt to reload config on map change?")
	
	LoadConfig() 
}

public Action:ReloadPets(client ,args)
{
	LoadConfig()
	ReplyToCommand(client, "Pets config has been successfully reloaded...")
	return Plugin_Handled;
}

stock LoadConfig()
{
	new Handle:kv = CreateKeyValues("Pets");
	
	new String:location[96]
	new String:text[96]
	new String:loc[4]
	BuildPath(Path_SM, location, sizeof(location), "configs/pets.cfg");
	for(new i = 1; i <= 256;i++)
	{
		FileToKeyValues(kv, location);
		Format(text, sizeof(text), "%i", i)
		if (!KvJumpToKey(kv, text))
		{
			KvJumpToKey(kv, "Downloads")
			for(new y = 1; y <= 8152; y++)
			{  
				IntToString(y, loc, sizeof(loc))
				KvGetString(kv, loc, text, sizeof(text), "mia")
				AddFileToDownloadsTable(text)
				
				if(StrEqual(text, "mia"))
				{
					break;
				}
			}
			if(i == 1 || i == 0)
			{
				SetFailState("[Pets] Unable to read sourcemod/configs/pets.cfg file. Have you setup everything correctly?")
			}
			LastIndex = i-1
			break;
		}
		KvGetString(kv, "name", petInfo[i][iName], 64);
		KvGetString(kv, "desc", petInfo[i][iDesc], 64);
		KvGetString(kv, "model", petInfo[i][iModel], 128);
		
		decl String:flags[32]
		KvGetString(kv, "adminflag", flags, 32, "0");
		
		if(StrEqual(flags, "0"))
		{
			petInfo[i][ADMFLAG] = 0;
		}
		else if(StrEqual(flags, "a"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_RESERVATION;
		}
		else if(StrEqual(flags, "b"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_GENERIC;
		}
		else if(StrEqual(flags, "c"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_KICK;
		}
		else if(StrEqual(flags, "d"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_BAN;
		}
		else if(StrEqual(flags, "e"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_UNBAN;
		}
		else if(StrEqual(flags, "f"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_SLAY;
		}
		else if(StrEqual(flags, "g"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CHANGEMAP;
		}
		else if(StrEqual(flags, "h"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CONVARS;
		}
		else if(StrEqual(flags, "i"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CONFIG;
		}
		else if(StrEqual(flags, "j"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CHAT;
		}
		else if(StrEqual(flags, "k"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_VOTE;
		}
		else if(StrEqual(flags, "l"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_PASSWORD;
		}
		else if(StrEqual(flags, "m"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_RCON;
		}
		else if(StrEqual(flags, "n"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CHEATS;
		}
		else if(StrEqual(flags, "o"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CUSTOM1;
		}
		else if(StrEqual(flags, "p"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CUSTOM2;
		}
		else if(StrEqual(flags, "q"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CUSTOM3;
		}
		else if(StrEqual(flags, "r"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CUSTOM4;
		}
		else if(StrEqual(flags, "s"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CUSTOM5;
		}
		else if(StrEqual(flags, "t"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_CUSTOM6;
		}
		else if(StrEqual(flags, "z"))
		{
			petInfo[i][ADMFLAG] = ADMFLAG_ROOT;
		}

		petInfo[i][CanBeColored] = KvGetNum(kv, "can_be_colored", 1)
		
		petInfo[i][SkinsAmount] = KvGetNum(kv, "skins")
		petInfo[i][iSoundAmount] = KvGetNum(kv, "sound_idle_amount")
		petInfo[i][Hidden] = KvGetNum(kv, "hidden")
		if(petInfo[i][iSoundAmount] > 0) 
		{
			KvGetString(kv, "sound_idle", petInfo[i][iSoundGeneric], 128);
			if(petInfo[i][iSoundAmount] > 1)
			{
				for(new e = 2; e <= petInfo[i][iSoundAmount]; e++)
				{
					Format(text, sizeof(text), "sound_idle_%i", e)
					switch(e)
					{ 
						case 2:	KvGetString(kv, text, petInfo[i][iSoundGeneric_2], 128, "Mia");
						case 3:	KvGetString(kv, text, petInfo[i][iSoundGeneric_3], 128, "Mia");
						case 4:	KvGetString(kv, text, petInfo[i][iSoundGeneric_4], 128, "Mia");
						case 5:	KvGetString(kv, text, petInfo[i][iSoundGeneric_5], 128, "Mia");
						case 6:	KvGetString(kv, text, petInfo[i][iSoundGeneric_6], 128, "Mia");
						case 7:	KvGetString(kv, text, petInfo[i][iSoundGeneric_7], 128, "Mia");
						case 8:	KvGetString(kv, text, petInfo[i][iSoundGeneric_8], 128, "Mia");
						case 9:	KvGetString(kv, text, petInfo[i][iSoundGeneric_9], 128, "Mia");
						case 10: KvGetString(kv, text, petInfo[i][iSoundGeneric_10], 128, "Mia");
					}
					if(StrEqual(text, "mia"))
					{
						break;
					}
				}
			} 
			if(petInfo[i][SkinsAmount] > 1)
			{
				KvGetString(kv, "skin_1_name", petInfo[i][iSkinName_1], 64)
				for(new e = 2; e <= petInfo[i][SkinsAmount]; e++)
				{
					Format(text, sizeof(text), "skin_%i_name", e)
					switch(e) 
					{ 
						case 2:	KvGetString(kv, text, petInfo[i][iSkinName_2], 64);
						case 3:	KvGetString(kv, text, petInfo[i][iSkinName_3], 64);
						case 4:	KvGetString(kv, text, petInfo[i][iSkinName_4], 64);
						case 5:	KvGetString(kv, text, petInfo[i][iSkinName_5], 64);
						case 6:	KvGetString(kv, text, petInfo[i][iSkinName_6], 64);
						case 7:	KvGetString(kv, text, petInfo[i][iSkinName_7], 64);
						case 8:	KvGetString(kv, text, petInfo[i][iSkinName_8], 64);
						case 9:	KvGetString(kv, text, petInfo[i][iSkinName_9], 64);
						case 10: KvGetString(kv, text, petInfo[i][iSkinName_10], 64);
					}
				}
			}
		}
		
		KvGetString(kv, "sound_jumping", petInfo[i][iSoundJump], 128);
		petInfo[i][iPitch] = KvGetNum(kv, "pitch")
		KvGetString(kv, "anim_idle", petInfo[i][iAnimIdle], 64);
		KvGetString(kv, "anim_walk", petInfo[i][iAnimWalk], 64);
		KvGetString(kv, "anim_jump", petInfo[i][iAnimJump], 64);
		petInfo[i][iHeight] = KvGetNum(kv, "height_type")
		petInfo[i][iHeight_Custom] = KvGetNum(kv, "height_custom")
		petInfo[i][SkinID] = KvGetNum(kv, "skin")
		petInfo[i][ModelScale] = KvGetFloat(kv, "modelscale") 
	}
	CloseHandle(kv);
}

public Action:PetName(client, args)
{
	decl String:argc[32]
	GetCmdArgString(argc, sizeof(argc))
	Format(petName[client], sizeof(petName[]), "%s", argc)
}

public Action:RandomizeMood(Handle:timer)
{
	if(GetConVarInt(MoodEnable) == 1)
	{
		for(new i = 1; i <= MaxClients;i++)
		{
			if(IsClientInGame(i) && petType[i] > 0)
			{
				petHappiness[i] = RoundFloat(GetRandomFloat(1.00, 27.00))
			}
		}
	}
}

PetSkin(client)
{
	new Handle:menu = CreateMenu(PetsSkin_Handler, MenuAction_Select | MenuAction_End);
	SetMenuExitBackButton(menu, true)
	
	SetMenuTitle(menu, "Pets - Main Menu - Choose Pet's Skin:");

	new String:Text[64]
	new String:value[4]
	switch(petSkin[client])
	{
		case 0: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_1])
		case 1: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_2])
		case 2: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_3])
		case 3: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_4])
		case 4: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_5])
		case 5: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_6])
		case 6: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_7])
		case 7: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_8])
		case 8: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_9])
		case 9: Format(Text, sizeof(Text), "Current Skin: %s", petInfo[petType[client]][iSkinName_10])
	}
	AddMenuItem(menu, "X", Text, ITEMDRAW_DISABLED)
	
	for(new i = 0; i < LastIndex-1; i++)
	{
		switch(i) 
		{
			case 0: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_1])
			case 1: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_2])
			case 2: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_3])
			case 3: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_4])
			case 4: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_5])
			case 5: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_6])
			case 6: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_7])
			case 7: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_8])
			case 8: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_9])
			case 9: Format(Text, sizeof(Text), "%s", petInfo[petType[client]][iSkinName_10])
		}
		IntToString(i, value, sizeof(value))
		AddMenuItem(menu, value, Text)
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PetsSkin_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			petSkin[client] = StringToInt(item);
			
			if(IsValidPet(pet[client]))
			{
				if(petSkin[client] > 0)
				{
					SetEntProp(pet[client], Prop_Send, "m_nSkin", petSkin[client])
				}
				else
				{
					SetEntProp(pet[client], Prop_Send, "m_nSkin", petInfo[petType[client]][SkinID]);
				}
			}
			
			PetSkin(client)
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					PetsMenu(client, 0);
					return;
				}
			}
		}
	}
}

public Action:PetsMenu(client, args)
{
	if(MenuNotUsable)
	{
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(PetsMenu_Handler, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Pets - Main Menu");
	
	AddMenuItem(menu, "0", "Pet's Status")
	AddMenuItem(menu, "1", "Pet's Type")
	if(petInfo[petType[client]][CanBeColored] == 1)
	{
		AddMenuItem(menu, "2", "Pet's Color")
	}
	else
	{
		AddMenuItem(menu, "2", "Pet's Color", ITEMDRAW_DISABLED)
	}
	if(petInfo[petType[client]][SkinsAmount] > 1)
	{
		AddMenuItem(menu, "3", "Pet's Skin")
	}
	else
	{
		AddMenuItem(menu, "X", "Pet's Skin", ITEMDRAW_DISABLED)
	}
/*	if(petType[client] > 0)
	{
		Format(pet_types, sizeof(pet_types), "Pet Type: %s", petInfo[petType[client]][iName])
		AddMenuItem(menu, "2", pet_types)
	}
	else
	{
		AddMenuItem(menu, "2", "Pet Type: No Pet Choosen")
	}
	
	if(petInfo[petType[client]][SkinsAmount] > 1)
	{
		switch(petSkin[client]) 
		{
			case 0: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_1])
			case 1: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_2])
			case 2: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_3])
			case 3: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_4])
			case 4: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_5])
			case 5: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_6])
			case 6: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_7])
			case 7: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_8])
			case 8: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_9])
			case 9: Format(pet_types, sizeof(pet_types), "Skin: %s", petInfo[petType[client]][iSkinName_10])
		}
		AddMenuItem(menu, "3", pet_types)
	}
	
	switch(petColor[client])
	{
		case 0:	AddMenuItem(menu, "1", "Pet Color: No Color");
		case 1:	AddMenuItem(menu, "1", "Pet Color: Red");
		case 2:	AddMenuItem(menu, "1", "Pet Color: Green");
		case 3:	AddMenuItem(menu, "1", "Pet Color: Blue");
		case 4:	AddMenuItem(menu, "1", "Pet Color: Pink");
		case 5:	AddMenuItem(menu, "1", "Pet Color: Orange");
		case 6:	AddMenuItem(menu, "1", "Pet Color: Cyan");
		case 7:	AddMenuItem(menu, "1", "Pet Color: Lime");
		case 8:	AddMenuItem(menu, "1", "Pet Color: Black");
		case 9:	AddMenuItem(menu, "1", "Pet Color: Team Based");
		case 10: AddMenuItem(menu, "1", "Pet Color: L-Team");
		case 11: AddMenuItem(menu, "1", "Pet Color: D-Team");
		case 12: AddMenuItem(menu, "1", "Pet Color: Magic");
	}*/

	if(StrEqual(petName[client], "Unnamed Fella"))
	{
		AddMenuItem(menu, "X", "Hint: Your pet is currently unnnamed. Use !petname command in chat to give your pet a name!", ITEMDRAW_DISABLED)
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public PetsMenu_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			new menuv = StringToInt(item)
			if(menuv == 0)
			{
				Command_Pet(client, 0)
			}
			else if(menuv == 1)
			{
				PetType(client)
			}
			else if(menuv == 2)
			{
				PetColor(client)
			}
			else if(menuv == 3)
			{
				PetSkin(client)
			}
			else
			{
				PetsMenu(client, 0)
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

PetType(client)
{
	new Handle:menu = CreateMenu(PetsType_Handler, MenuAction_Select | MenuAction_End);
	SetMenuExitBackButton(menu, true)
	
	SetMenuTitle(menu, "Pets - Main Menu - Choose Your Pet:");

	new String:Text[64]
	new String:value[4]
	if(petType[client] == 0)
	{
		Format(Text, sizeof(Text), "Current Pet: No Pet")
	}
	else
	{
		Format(Text, sizeof(Text), "Current Pet: %s", petInfo[petType[client]][iName])
	}
	AddMenuItem(menu, "X", Text, ITEMDRAW_DISABLED)
	
	AddMenuItem(menu, "150", "No Pet")
	
	new bits;
	for(new i = 1; i <= 256; i++)
	{
		if(strlen(petInfo[i][iName]) > 3)
		{
			IntToString(i, value, sizeof(value))
			bits = GetUserFlagBits(client)
			if(petInfo[i][ADMFLAG] == 0 || bits & petInfo[i][ADMFLAG] || bits & ADMFLAG_ROOT)
			{
				Format(Text, sizeof(Text), "%s", petInfo[i][iName])
				AddMenuItem(menu, value, Text)
			}
			else
			{
				if(petInfo[i][Hidden] != 1)
				{
					Format(Text, sizeof(Text), "%s (No Access)", petInfo[i][iName])
					AddMenuItem(menu, value, Text, ITEMDRAW_DISABLED)
				}
			}
		}
		else
		{
			break;
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PetsType_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			new value = StringToInt(item);
			if(!petChangeCooldown[client])
			{
				if(petType[client] != value)
				{
					if(GetConVarInt(PetCooldown) >= 1)
					{
						petChangeCooldown[client] = true;
						CreateTimer(float(GetConVarInt(PetCooldown)), ResetCooldown, EntIndexToEntRef(client))
					}
					
					if(value == 150)
					{
						if(petType[client] != 0)
						{
							petType[client] = 0;
							petSkin[client] = 0;
							KillPet(client);
							petChangeCooldown[client] = false;
						}
					}
					else
					{ 
						if(IsPlayerAlive(client))
						{
							petType[client] = value;
							petSkin[client] = 0;
							KillPet(client);
							SpawnPet(client);
						}
					}
				}
				PetType(client)
			}
			else
			{
				PrintToChat(client, "You can't change your pet right now. Please try again later!")
				PetType(client)
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					PetsMenu(client, 0);
					return;
				}
			}
		}
	}
}

public Action:ResetCooldown(Handle:timer, any:ref)
{
	new client = EntRefToEntIndex(ref)
	if(client != INVALID_ENT_REFERENCE)
	{
		petChangeCooldown[client] = false;
	}
}

PetColor(client)
{
	new Handle:menu = CreateMenu(PetsColor_Handler, MenuAction_Select | MenuAction_End);
	SetMenuExitBackButton(menu, true)
	
	SetMenuTitle(menu, "Pets - Main Menu - Choose Your Pet's Color:");
	new String:Text[64] 
	switch(petColor[client])
	{
		case 0: Format(Text, sizeof(Text), "Current Color: No Color")
		case 1: Format(Text, sizeof(Text), "Current Color: Red")
		case 2: Format(Text, sizeof(Text), "Current Color: Green")
		case 3: Format(Text, sizeof(Text), "Current Color: Blue")
		case 4: Format(Text, sizeof(Text), "Current Color: Pink")
		case 5: Format(Text, sizeof(Text), "Current Color: Orange")
		case 6: Format(Text, sizeof(Text), "Current Color: Cyan")
		case 7: Format(Text, sizeof(Text), "Current Color: Lime")
		case 8: Format(Text, sizeof(Text), "Current Color: Black")
		case 9: Format(Text, sizeof(Text), "Current Color: Team Based")
		case 10: Format(Text, sizeof(Text), "Current Color: L-Team")
		case 11: Format(Text, sizeof(Text), "Current Color: D-Team")
		case 12: Format(Text, sizeof(Text), "Current Color: Magic")
	}
	
	AddMenuItem(menu, "X", Text, ITEMDRAW_DISABLED)
	
	AddMenuItem(menu, "0", "No Color");
	AddMenuItem(menu, "1", "Red");
	AddMenuItem(menu, "2", "Green");
	AddMenuItem(menu, "3", "Blue");
	AddMenuItem(menu, "4", "Pink");
	AddMenuItem(menu, "5", "Orange");
	AddMenuItem(menu, "6", "Cyan");
	AddMenuItem(menu, "7", "Lime");
	AddMenuItem(menu, "8", "Black");
	AddMenuItem(menu, "9", "Team Based");
	AddMenuItem(menu, "10", "L-Team");
	AddMenuItem(menu, "11", "D-Team");
	AddMenuItem(menu, "12", "Magic");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PetsColor_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			petColor[client] = StringToInt(item);
			
			if(petInfo[petType[client]][CanBeColored] == 1)
			{
				if(IsValidPet(pet[client]))
				{
					SetEntityRenderColor(pet[client], 255, 255, 255)
					switch(petColor[client])
					{
						case PETCOLOR_RED: SetEntityRenderColor(pet[client], 255, 0, 0, 255);
						case PETCOLOR_GREEN: SetEntityRenderColor(pet[client], 0, 255, 0, 255);
						case PETCOLOR_BLUE: SetEntityRenderColor(pet[client], 0, 0, 255, 255);
						case PETCOLOR_PINK: SetEntityRenderColor(pet[client], 255, 0, 255, 255);
						case PETCOLOR_ORANGE: SetEntityRenderColor(pet[client], 255, 128, 0, 255);
						case PETCOLOR_CYAN: SetEntityRenderColor(pet[client], 128, 255, 255, 255);
						case PETCOLOR_LIME: SetEntityRenderColor(pet[client], 128, 255, 0, 255);
						case PETCOLOR_BLACK: SetEntityRenderColor(pet[client], 0, 0, 0, 255);
						case PETCOLOR_TEAM:
						{ 
							if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 255, 0, 0, 255);
							else	SetEntityRenderColor(pet[client], 0, 0, 255, 255);
						}
						case PETCOLOR_LTEAM:
						{
							if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 255, 128, 128, 255);
							else	SetEntityRenderColor(pet[client], 128, 128, 255, 255);
						}
						case PETCOLOR_DTEAM:
						{
							if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 128, 0, 0, 255);
							else	SetEntityRenderColor(pet[client], 0, 0, 128, 255);
						}
						case PETCOLOR_MAGIC: SetEntityRenderColor(pet[client], GetRandomInt(0, 2) * 127 + 1, GetRandomInt(0, 2) * 127 + 1, GetRandomInt(0, 2) * 127 + 1, 255);
					}
				}
			}
			else
			{
				PrintToChat(client, "Sorry but this pet is not colorable!")
				PetsMenu(client, 0)
			}
			PetColor(client)
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					PetsMenu(client, 0);
					return;
				}
			}
		}
	}
}

/*public PetsMenu_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			new menuv = StringToInt(item)
			if(menuv == 0)
			{
				Command_Pet(client, 0)
			}
			else if(menuv == 1)
			{
				if(petColor[client] > -1 && petColor[client] < 12)
				{
					petColor[client]++
				}
				else
				{
					petColor[client] = 0;
				}
				
				if(pet[client] > 0 && IsValidEntity(pet[client]))
				{
					SetEntityRenderColor(pet[client], 255, 255, 255)
					switch(petColor[client])
					{
						case PETCOLOR_RED: SetEntityRenderColor(pet[client], 255, 0, 0, 255);
						case PETCOLOR_GREEN: SetEntityRenderColor(pet[client], 0, 255, 0, 255);
						case PETCOLOR_BLUE: SetEntityRenderColor(pet[client], 0, 0, 255, 255);
						case PETCOLOR_PINK: SetEntityRenderColor(pet[client], 255, 0, 255, 255);
						case PETCOLOR_ORANGE: SetEntityRenderColor(pet[client], 255, 128, 0, 255);
						case PETCOLOR_CYAN: SetEntityRenderColor(pet[client], 128, 255, 255, 255);
						case PETCOLOR_LIME: SetEntityRenderColor(pet[client], 128, 255, 0, 255);
						case PETCOLOR_BLACK: SetEntityRenderColor(pet[client], 0, 0, 0, 255);
						case PETCOLOR_TEAM:
						{
							if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 255, 0, 0, 255);
							else	SetEntityRenderColor(pet[client], 0, 0, 255, 255);
						}
						case PETCOLOR_LTEAM:
						{
							if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 255, 128, 128, 255);
							else	SetEntityRenderColor(pet[client], 128, 128, 255, 255);
						}
						case PETCOLOR_DTEAM:
						{
							if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 128, 0, 0, 255);
							else	SetEntityRenderColor(pet[client], 0, 0, 128, 255);
						}
						case PETCOLOR_MAGIC: SetEntityRenderColor(pet[client], GetRandomInt(0, 2) * 127 + 1, GetRandomInt(0, 2) * 127 + 1, GetRandomInt(0, 2) * 127 + 1, 255);
					}
				}
				PetsMenu(client, 0)
			}
			else if(menuv == 2)
			{
				if(petType[client] < LastIndex)
				{
					petType[client]++
				}
				else
				{
					petType[client] = 1;
				}
				PetsMenu(client, 0)
			}
			else if(menuv == 3)
			{
				if(petSkin[client] < petInfo[petType[client]][SkinsAmount]-1)
				{
					petSkin[client]++
				} 
				else
				{
					petSkin[client] = 0;
				}
				
				if(pet[client] > 0 && IsValidEntity(pet[client]))
				{
					if(petSkin[client] > 0)
					{
						SetEntProp(pet[client], Prop_Send, "m_nSkin", petSkin[client])
					}
					else
					{
						SetEntProp(pet[client], Prop_Send, "m_nSkin", petInfo[petType[client]][SkinID]);
					}
				}
				PetsMenu(client, 0)
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}*/

public OnPluginEnd()
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsValidEntity(pet[i])) continue;
		KillPet(i);
	}
}

public OnMapStart()
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsValidEntity(pet[i])) continue;
		KillPet(i);
	}
	PrecacheSound(SOUND_SPAWN);
	for(new i=1; i<sizeof(petInfo); i++)
	{
		if(strlen(petInfo[i][iModel]) < 4)
		{
			break;
		}
		PrecacheModel(petInfo[i][iModel]);
		
		if(strlen(petInfo[i][iSoundGeneric]) > 3)
		{
			PrecacheSound(petInfo[i][iSoundGeneric]);
			for (new e = 2; e <= petInfo[i][iSoundAmount]; e++)
			{
				switch(e)
				{
					case 2: PrecacheSound(petInfo[i][iSoundGeneric_2]);
					case 3: PrecacheSound(petInfo[i][iSoundGeneric_3]);
					case 4: PrecacheSound(petInfo[i][iSoundGeneric_4]);
					case 5: PrecacheSound(petInfo[i][iSoundGeneric_5]);
					case 6: PrecacheSound(petInfo[i][iSoundGeneric_6]);
					case 7: PrecacheSound(petInfo[i][iSoundGeneric_7]);
					case 8: PrecacheSound(petInfo[i][iSoundGeneric_8]);
					case 9: PrecacheSound(petInfo[i][iSoundGeneric_9]);
					case 10: PrecacheSound(petInfo[i][iSoundGeneric_10]);
				}
			}
		}
		if(strlen(petInfo[i][iSoundJump]) > 3)
		{
			PrecacheSound(petInfo[i][iSoundJump]);
		}
	}
	
	if(GetConVarInt(Reload) == 1)
	{
		LoadConfig()
	}
}

public OnClientPutInServer(client)
{
	pet[client] = 0;
	petColor[client] = 0; 
	petHappiness[client] = 0;
	petType[client] = 0;
	petSkin[client] = 0;
	petChangeCooldown[client] = false;
}

public OnClientDisconnect(client)
{
	KillPet(client);
}

public Action:Command_Pet(client, args)
{
	if(MenuNotUsable)
	{
		return Plugin_Handled;
	}
	if(petType[client] == 0 && pet[client] < 1)
	{
		PrintToChat(client, "You don't have a pet! Specify what kind of pet you want before reviewing him!");
		PetsMenu(client, 0)
		return Plugin_Handled;
	}
	
	new Handle:panel = CreatePanel();
	
	if(strlen(petName[client]) < 2)
	{
		Format(petName[client], sizeof(petName[]), "Unnamed Fella");
	}
	
	decl String:line[64];
	Format(line, sizeof(line), "%s the %s", petName[client], petInfo[petType[client]][iName]);
	
	SetPanelTitle(panel, line);
	
	if(GetConVarInt(MoodEnable) == 1)
	{
		if(petHappiness[client] == 0)
		{
			Format(line, sizeof(line), "Mood: Unknown");
		}
		else
		{
			if(petHappiness[client] >= 16)
				Format(line, sizeof(line), "Mood: Supreme");
			else if(petHappiness[client] >= 8)
				Format(line, sizeof(line), "Mood: Content");
			else if(petHappiness[client] >= 4)
				Format(line, sizeof(line), "Mood: Poor");
			else
				Format(line, sizeof(line), "Mood: Terrible");
		}
		DrawPanelText(panel, line);
	}
	
	DrawPanelText(panel, " ");
	
//	if(petEnabled[client])
//		DrawPanelItem(panel, "Put Away");
//	else
//		DrawPanelItem(panel, "Send Out");
		
	DrawPanelItem(panel, "Back");
	
	SendPanelToClient(panel, client, Menu_Pet, 60);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Menu_Pet(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select)
	{
		PetsMenu(client, 0)
	}
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	
	if(petType[client] > 0)
	{
		if(IsValidPet(pet[client]))
			KillPet(client);
		SpawnPet(client);
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidPet(pet[client]))
		KillPet(client);
}

SpawnPet(client)
{
	if(petType[client] == 0)
		return;
	
	if(petHappiness[client] == 0)
	{
		petHappiness[client] = RoundFloat(GetRandomFloat(5.00, 20.00))
	}
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	OffsetLocation(pos);
	
	if(!(pet[client] = CreateEntityByName("prop_dynamic_override")))
		return;
	PrecacheModel(petInfo[petType[client]][iModel]);
	SetEntityModel(pet[client], petInfo[petType[client]][iModel]);
	DispatchKeyValue(pet[client], "targetname", "tf2_pet")
	DispatchSpawn(pet[client]);
	TeleportEntity(pet[client], pos, NULL_VECTOR, NULL_VECTOR);
	
	if(petSkin[client] > 0)
	{
		SetEntProp(pet[client], Prop_Send, "m_nSkin", petSkin[client])
	}
	else
	{
		SetEntProp(pet[client], Prop_Send, "m_nSkin", petInfo[petType[client]][SkinID]);
	}
	
	if(petInfo[petType[client]][ModelScale] > 0.00)
	{ 
		SetEntPropFloat(pet[client], Prop_Send, "m_flModelScale", petInfo[petType[client]][ModelScale])
	}
	
	new value = RoundFloat(GetRandomFloat(1.00, float(petInfo[petType[client]][iSoundAmount])))
	switch(value)
	{
		case 1: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 2: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_2], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 3: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_3], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 4: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_4], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 5: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_5], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 6: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_6], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 7: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_7], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 8: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_8], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 9: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_9], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 10: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_10], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
	}
	EmitAmbientSound(SOUND_SPAWN, pos); 
	
	SetEntityRenderMode(pet[client], RENDER_TRANSADD);
	if(petInfo[petType[client]][CanBeColored] == 1)
	{
		switch(petColor[client])
		{
			case PETCOLOR_RED: SetEntityRenderColor(pet[client], 255, 0, 0, 255);
			case PETCOLOR_GREEN: SetEntityRenderColor(pet[client], 0, 255, 0, 255);
			case PETCOLOR_BLUE: SetEntityRenderColor(pet[client], 0, 0, 255, 255);
			case PETCOLOR_PINK: SetEntityRenderColor(pet[client], 255, 0, 255, 255);
			case PETCOLOR_ORANGE: SetEntityRenderColor(pet[client], 255, 128, 0, 255);
			case PETCOLOR_CYAN: SetEntityRenderColor(pet[client], 128, 255, 255, 255);
			case PETCOLOR_LIME: SetEntityRenderColor(pet[client], 128, 255, 0, 255);
			case PETCOLOR_BLACK: SetEntityRenderColor(pet[client], 0, 0, 0, 255);
			case PETCOLOR_TEAM:
			{
				if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 255, 0, 0, 255);
				else	SetEntityRenderColor(pet[client], 0, 0, 255, 255);
			}
			case PETCOLOR_LTEAM:
			{
				if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 255, 128, 128, 255);
				else	SetEntityRenderColor(pet[client], 128, 128, 255, 255);
			}
			case PETCOLOR_DTEAM:
			{
				if(GetClientTeam(client) == 2) SetEntityRenderColor(pet[client], 128, 0, 0, 255);
				else	SetEntityRenderColor(pet[client], 0, 0, 128, 255);
			}
			case PETCOLOR_MAGIC: SetEntityRenderColor(pet[client], GetRandomInt(0, 2) * 127 + 1, GetRandomInt(0, 2) * 127 + 1, GetRandomInt(0, 2) * 127 + 1, 255);
		}
	}
	if(strlen(petName[client]) < 2)
	{
		Format(petName[client], sizeof(petName[]), "Unnamed Fella");
	}
	
	if(GetConVarInt(MoodEnable) == 1)
	{
		if(petHappiness[client] >= 17)
		{
			PrintToChat(client, "%s%s\x01: Hi, %N!", NPCCOLOR, petName[client], client);
		}
		else if(petHappiness[client] >= 9)
		{
			PrintToChat(client, "%s%s\x01: Hi, %N.", NPCCOLOR, petName[client], client);
		}
		else if(petHappiness[client] >=5)
		{
			PrintToChat(client, "%s%s\x01: Hey %N, I'm kind of angry...", NPCCOLOR, petName[client], client);
		}
		else if(petHappiness[client] >= 1)
		{
			PrintToChat(client, "%s%s\x01: Arghhh...", NPCCOLOR, petName[client]);
		}
	}
	else
	{
		PrintToChat(client, "%s%s\x01: Hi, %N!", NPCCOLOR, petName[client], client);
	}

	SDKHook(client, SDKHook_PreThink, PetThink);
	
	if(soundTimer[client] != INVALID_HANDLE)
	{
		KillTimer(soundTimer[client]);
		soundTimer[client] = INVALID_HANDLE;
	} 
	soundTimer[client] = CreateTimer(10.0, Timer_GenericSound, client);
}

public PetThink(client) 
{
	if(!IsValidPet(pet[client]))
	{
		SDKUnhook(client, SDKHook_PreThink, PetThink);
		return;
	}

	// Get locations, angles, distances
	decl Float:pos[3], Float:ang[3], Float:clientPos[3];
	GetEntPropVector(pet[client], Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(pet[client], Prop_Data, "m_angRotation", ang);
	GetClientAbsOrigin(client, clientPos);

	new Float:dist = GetVectorDistance(clientPos, pos);
	new Float:distX = clientPos[0] - pos[0];
	new Float:distY = clientPos[1] - pos[1];
	new Float:speed = (dist - 64.0) / 54;
	Math_Clamp(speed, -4.0, 4.0);
	if(FloatAbs(speed) < 0.3)
		speed *= 0.1;
	
	// Teleport to owner if too far
	if(dist > 1024.0)
	{
		decl Float:posTmp[3];
		GetClientAbsOrigin(client, posTmp);
		OffsetLocation(posTmp);
		TeleportEntity(pet[client], posTmp, NULL_VECTOR, NULL_VECTOR);
		GetEntPropVector(pet[client], Prop_Data, "m_vecOrigin", pos);
	}
	
	// Set new location data	
	if(pos[0] < clientPos[0])	pos[0] += speed;
	if(pos[0] > clientPos[0])	pos[0] -= speed;
	if(pos[1] < clientPos[1])	pos[1] += speed;
	if(pos[1] > clientPos[1])	pos[1] -= speed;
	
	// Height
	switch(petInfo[petType[client]][iHeight])
	{
		case 1: pos[2] = clientPos[2]
		case 2: pos[2] = clientPos[2] + petInfo[petType[client]][iHeight_Custom];
	}
	 
	// Pet states
	if(!(GetEntityFlags(client) & FL_ONGROUND))
		SetPetState(client, STATE_JUMPING);
	else if(FloatAbs(speed) > 0.2)
		SetPetState(client, STATE_WALKING);
	else
		SetPetState(client, STATE_IDLE);
	 
	// Look at owner
	ang[1] = (ArcTangent2(distY, distX) * 180) / 3.14;
	
	// Finalize new location
	/*if(TR_GetPointContents(pos) == 1)
		return;*/
	
	TeleportEntity(pet[client], pos, ang, NULL_VECTOR);
	
	if(petParticle[client] != 0)
	{
		pos[2] += 4.0;
		TeleportEntity(petParticle[client], pos, ang, NULL_VECTOR);
	}
}

stock Entity_GetAbsOrigin(entity, Float:vec[3]) // Thanks to SMLIB for this stock!
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
}

stock any:Math_Clamp(any:value, any:min, any:max) // Thanks to SMLIB for this stock!
{
	value = Math_Min(value, min);
	value = Math_Max(value, max);

	return value;
}

/*
Float:GetClientPos(client)
{
	decl Float:XYZ[3]
	GetEntPropVector(pet[client], Prop_Send, "m_vecOrigin", XYZ);
	
	new Float:Area[3]
	Area[0] = XYZ[0]
	Area[1] = XYZ[1]
	Area[2] = -900000000000000.0
	
	new Handle:trace = TR_TraceRayFilterEx(XYZ, Area, MASK_NPCSOLID, RayType_EndPoint, FilterSCP, client);
	if (TR_DidHit(trace))
	{
		decl Float:Stuff[3];
		TR_GetEndPosition(Stuff, trace);
		return Stuff[2];
	}
	CloseHandle(trace);
	return XYZ[2];
}*/

public bool:FilterSCP(entity, contentsMask, any:client)
{
    if (entity == client || entity == pet[client])
    {
        return false;
    }
    
    return true;
}

public Action:Timer_GenericSound(Handle:timer, any:client)
{
	if(!IsValidPet(pet[client]))
	{
		KillTimer(timer);
		soundTimer[client] = INVALID_HANDLE; 
		return Plugin_Handled;
	}
	 
	decl Float:pos[3];
	GetEntPropVector(pet[client], Prop_Data, "m_vecOrigin", pos);
	
	new value = RoundFloat(GetRandomFloat(1.00, float(petInfo[petType[client]][iSoundAmount])))
	switch(value)
	{
		case 1: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 2: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_2], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 3: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_3], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 4: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_4], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 5: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_5], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 6: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_6], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 7: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_7], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 8: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_8], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 9: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_9], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
		case 10: EmitAmbientSound(petInfo[petType[client]][iSoundGeneric_10], pos, pet[client], _, _, 0.5, petInfo[petType[client]][iPitch]);
	}
	
	
	soundTimer[client] = CreateTimer(GetRandomFloat(20.0, 60.0), Timer_GenericSound, client);
	return Plugin_Continue;
}
 
SetPetState(client, status)
{ 
	decl Float:pos[3];
	GetEntPropVector(pet[client], Prop_Data, "m_vecOrigin", pos);
	if(petState[client] == status) return;
	switch(status)
	{
		case STATE_IDLE: SetPetAnim(client, petInfo[petType[client]][iAnimIdle]);
		case STATE_WALKING: SetPetAnim(client, petInfo[petType[client]][iAnimWalk]);
		case STATE_JUMPING:
		{
			SetPetAnim(client, petInfo[petType[client]][iAnimJump]);
			EmitAmbientSound(petInfo[petType[client]][iSoundJump], pos, pet[client], _, _, 0.13, petInfo[petType[client]][iPitch]);
		}
	}
	petState[client] = status;
}

SetPetAnim(client, const String:anim[])
{
	SetVariantString(anim);
	AcceptEntityInput(pet[client], "SetAnimation");
}

OffsetLocation(Float:pos[3])
{
	pos[0] += GetRandomFloat(-128.0, 128.0);
	pos[1] += GetRandomFloat(-128.0, 128.0);
}

KillPet(client)
{
	if(pet[client] == 0)
		return;
	
	decl Float:pos[3];
	Entity_GetAbsOrigin(pet[client], pos);
	
	SDKUnhook(client, SDKHook_PreThink, PetThink);
	AcceptEntityInput(pet[client], "Kill");
	pet[client] = 0;
	
	if(petParticle[client] != 0)
	{
		AcceptEntityInput(petParticle[client], "Kill");
		petParticle[client] = 0;
	}
}

stock bool:IsValidPet(entity)
{
	if(entity > 0 && IsValidEntity(entity))
	{
		decl String:strName[16];
		GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(StrEqual(strName, "tf2_pet"))
		{
			return true;
		}
	}
	return false;
}

stock any:Math_Min(any:value, any:min) // Thanks to SMLIB for this stock!
{
	if (value < min) {
		value = min;
	}
	
	return value;
}

stock any:Math_Max(any:value, any:max) // Thanks to SMLIB for this stock!
{	
	if (value > max) {
		value = max;
	}
	
	return value;
}