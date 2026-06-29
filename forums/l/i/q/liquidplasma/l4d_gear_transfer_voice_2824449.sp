#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#define	MAX_SURVIVORS	8
#define NICK 'b'
#define ROCHELLE 'd'
#define COACH 'c'
#define ELLIS 'h'
#define BILL 'v'
#define ZOEY 'n'
#define FRANCIS 'e'
#define LOUIS 'a'


ConVar g_cOnlyBots; bool g_bOnlyBots;
ConVar g_hChance;	int g_iChance;

#define PLUGIN_VERSION		"1.1"
#define PLUGIN_NAME			"l4d_gear_transfer_voice"
#define PLUGIN_NAME_FULL	"[L4D2] Players will vocalize thanks when receiving"
#define PLUGIN_DESCRIPTION	"Players will vocalise thanks when receiving item from SilverShot's Gear Transfer"
#define PLUGIN_AUTHOR		"liquidplasma"
#define PLUGIN_LINK			""

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

// Shamelessly taken from [L4D2] Survivor Bot Holdout by SilverShot
// https://forums.alliedmods.net/showthread.php?p=1741099
char g_sLines_Nick[17][] =
{
	"AlertGiveItem01",			// It is more blessed to give than to receive.
	"AlertGiveItem02",			// Have this.
	"AlertGiveItem03",			// Just take this.
	"AlertGiveItem04",			// This is for you.
	"AlertGiveItem05",			// Here, I don't need this.
	"AlertGiveItem06",			// Take it, just take it.
	"AlertGiveItemC101",		// Hey you, take this.
	"AlertGiveItemC102",		// What's your name, here you go.
	"AlertGiveItemCombat01",	// Take this.
	"AlertGiveItemCombat02",	// Grab this.
	"AlertGiveItemCombat03",	// Take it.
	"AlertGiveItemStop01",		// Stop, I have something for you.
	"AlertGiveItemStop02",		// Hang on, you need this more than me.
	"AlertGiveItemStop03",		// Hold up, you can have this.
	"AlertGiveItemStop04",		// Hold up, you can have this.
	"AlertGiveItemStop05",		// Hang on, you need this more than me.
	"AlertGiveItemStop06"		// Stop, I have something for you.
};

char g_sLines_Rochelle[16][] =
{
	"AlertGiveItem01",			// You can have this.
	"AlertGiveItem02",			// Got this just for you.
	"AlertGiveItem03",			// Here, you can have this.
	"AlertGiveItem04",			// A little something for you.
	"AlertGiveItem05",			// I picked this up just for you.
	"AlertGiveItemC101",		// You're gonna need this.
	"AlertGiveItemCombat01",	// Here!
	"AlertGiveItemCombat02",	// Take this!
	"AlertGiveItemCombat03",	// Have this!
	"AlertGiveItemCombat04",	// Here, use this.
	"AlertGiveItemCombat05",	// You need this, take this!
	"AlertGiveItemCombat06",	// Here, I'm giving this to you.
	"AlertGiveItemStop01",		// Wait, I have something for you.
	"AlertGiveItemStop02",		// STOP, take this.
	"AlertGiveItemStop03",		// Can you stop for a sec? I got something for you.
	"AlertGiveItemStopC101"		// Hey! Hey, uh, you!  I got something for you.
};

char g_sLines_Coach[18][] =
{
	"AlertGiveItem01",			// Take it. Hell, I don't need it.
	"AlertGiveItem02",			// You make sure you use this now.
	"AlertGiveItem03",			// Ain't no shame in gettin' some help.
	"AlertGiveItem04",			// Take this.
	"AlertGiveItem05",			// Here ya go.
	"AlertGiveItemC101",		// You can have this.
	"AlertGiveItemC102",		// Excuse me, here ya go.
	"AlertGiveItemC103",		// Hey, you can have this.
	"AlertGiveItemCombat01",	// Take it.
	"AlertGiveItemCombat02",	// Here.
	"AlertGiveItemCombat03",	// Have it.
	"AlertGiveItemCombat04",	// Take it.
	"AlertGiveItemCombat05",	// Here.
	"AlertGiveItemStop01",		// Hold on, I got something for you.
	"AlertGiveItemStop02",		// Hold up now, I got something for you.
	"AlertGiveItemStop03",		// Hold up, I got something for you.
	"AlertGiveItemStopC101",	// Yo! I got somethin' for ya.
	"AlertGiveItemStopC102"		// Hey! Hey! Hold up.
};

char g_sLines_Ellis[20][] =
{
	"AlertGiveItem01",			// I got this for ya, man.
	"AlertGiveItem02",			// I want you to have this.
	"AlertGiveItem03",			// Here ya go, I got this for ya.
	"AlertGiveItem04",			// Here ya go, man.
	"AlertGiveItem05",			// Here ya go, man, I want ya to have this.
	"AlertGiveItem06",			// You can have this.
	"AlertGiveItem07",			// Hey, I want you to have this.
	"AlertGiveItem08",			// Hold on now, hold on now, here ya go.
	"AlertGiveItemCombat01",	// Take this!
	"AlertGiveItemCombat02",	// Just take this!
	"AlertGiveItemCombat03",	// Here!, here!
	"AlertGiveItemCombat04",	// Grab this here!
	"AlertGiveItemStop01",		// Wait up, now! I got somethin' for ya.
	"AlertGiveItemStop02",		// Hey! Hey! Got something for ya.
	"AlertGiveItemStop03",		// Hey, stop movin', now! I got somethin' for you right here.
	"AlertGiveItemStop04",		// Wait up! I got somethin' for ya.
	"AlertGiveItemStop05",		// Hey! Hey! Got something for ya.
	"AlertGiveItemStop06",		// Hey, stop movin' I got somethin' for ya
	"AlertGiveItemStopC101",	// Dude, dude, hold up.
	"AlertGiveItemStopC102"		// Hey umm...  you! Hold up!
};

char g_sLines_Bill[7][] =
{
	"AlertGiveItem01",
	"AlertGiveItem02",
	"AlertGiveItem03",
	"AlertGiveItem04",
	"AlertGiveItem05",
	"AlertGiveItem06",
	"AlertGiveItem07",
};

char g_sLines_Zoey[10][] =
{
	"AlertGiveItem01",
	"AlertGiveItem03",
	"AlertGiveItem05",
	"AlertGiveItem07",
	"AlertGiveItem09",
	"AlertGiveItem11",
	"AlertGiveItem12",
	"AlertGiveItem14",
	"AlertGiveItem15",
	"AlertGiveItem16",
};

char g_sLines_Louis[7][] =
{
	"AlertGiveItem01",
	"AlertGiveItem02",
	"AlertGiveItem03",
	"AlertGiveItem04",
	"AlertGiveItem05",
	"AlertGiveItem06",
	"AlertGiveItem07",
};

char g_sLines_Francis[7][] =
{
	"AlertGiveItem01",
	"AlertGiveItem02",
	"AlertGiveItem03",
	"AlertGiveItem04",
	"AlertGiveItem05",
	"AlertGiveItem06",
	"AlertGiveItem07",
};

//Zoey has lots of Thanks
int ZoeyThanksGeneric[] = {
    1, 2, 3, 4, 6, 7, 8, 9, 11, 13, 19, 20, 23, 24, 25, 27, 28, 30
}
int ZoeyThanksLouis[] = {
	32, 34, 35, 42, 43, 45, 46
}
int ZoeyThanksBill[] = {
	5, 40
}
int ZoeyThanksFrancis[] = {
	41, 44
}

//Francis
int FrancisThanksGeneric[] = {
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
}
int FrancisThanksLouis[] = {
	18, 19
}
#define Francis_ThanksBill 16
#define Francis_ThanksZoey 17

//Louis
int LouisThanksGeneric[] = {
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14
}
#define Louis_ThanksZoey 13

public void OnPluginStart()
{
    g_cOnlyBots = 	CreateConVar(PLUGIN_NAME ... "_players", 		"0", 	"Enable to also have players vocalize (1 = enabled, 0 = disabled)", FCVAR_NOTIFY);
	g_hChance =		CreateConVar(PLUGIN_NAME ... "_thanks_chance",	"0", 	"1 in x chance for the recipient to say thanks after receiving a item, 0 = always", FCVAR_NOTIFY, true, 0.0);
	g_cOnlyBots.AddChangeHook(ChangeSetting);
	AutoExecConfig(true, PLUGIN_NAME);
	UpdateSettings();
}

public void ChangeSetting(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UpdateSettings();
}

void UpdateSettings()
{
	g_bOnlyBots = g_cOnlyBots.BoolValue;
	g_iChance = g_hChance.IntValue;
}

public void OnAllPluginsLoaded()
{
	Handle gearTransfer = FindPluginByFile("l4d_gear_transfer.smx");
	if (gearTransfer != INVALID_HANDLE)
	{
		if (GetPluginStatus(gearTransfer) != Plugin_Running)
			SetFailState("Gear Transfer paused or not running, quitting plugin...");
	}
	else
		SetFailState("Gear Transfer not found, quitting plugin...");
}

public void GearTransfer_OnWeaponGive(int client, int target, int item)
{
    if (!IsFakeClient(client) && !g_bOnlyBots)
        return;

    if (client && target)
    {
        static char giverModel[31];
		GetEntPropString(client, Prop_Data, "m_ModelName", giverModel, sizeof(giverModel));
		DataPack pack;
		CreateDataTimer(2.0, VocalizeThanks, pack);
		pack.WriteCell(client);
		pack.WriteCell(target);
 		static char sTemp[64];
        switch(giverModel[29])
        {
            case NICK: // Nick
            {
                // Sound
                int random = GetRandomInt(0, sizeof(g_sLines_Nick) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/gambler/%s.vcd", g_sLines_Nick[random]);
                VocalizeScene(client, sTemp);
            }
            case ROCHELLE: // Rochelle
            {
                int random = GetRandomInt(0, sizeof(g_sLines_Rochelle) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/producer/%s.vcd", g_sLines_Rochelle[random]);
                VocalizeScene(client, sTemp);
            }
            case COACH: // Coach
            {
                int random = GetRandomInt(0, sizeof(g_sLines_Coach) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/coach/%s.vcd", g_sLines_Coach[random]);
                VocalizeScene(client, sTemp);
            }
            case ELLIS: // Ellis
            {
                int random = GetRandomInt(0, sizeof(g_sLines_Ellis) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/mechanic/%s.vcd", g_sLines_Ellis[random]);
                VocalizeScene(client, sTemp);
            }
            case BILL: // Bill
            {
                int random = GetRandomInt(0, sizeof(g_sLines_Bill) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/namvet/%s.vcd", g_sLines_Bill[random]);
                VocalizeScene(client, sTemp);
            }
            case ZOEY: // Zoey
            {
                int random = GetRandomInt(0, sizeof(g_sLines_Zoey) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/teengirl/%s.vcd", g_sLines_Zoey[random]);
                VocalizeScene(client, sTemp);
            }
            case FRANCIS: // Francis
            {
                int random = GetRandomInt(0, sizeof(g_sLines_Francis) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/biker/%s.vcd", g_sLines_Francis[random]);
                VocalizeScene(client, sTemp);
            }
            case LOUIS: // Louis
            {
                int random = GetRandomInt(0, sizeof(g_sLines_Louis) - 1);
                Format(sTemp, sizeof(sTemp), "scenes/manager/%s.vcd", g_sLines_Louis[random]);
                VocalizeScene(client, sTemp);
            }
        }
    }
}

bool ChanceCheck()
{
	if (g_iChance == 0)
		return true;

	return GetRandomInt(0, g_iChance - 1) == 0;
}

Action VocalizeThanks(Handle timer, DataPack pack)
{
	if (!ChanceCheck())
		return Plugin_Handled;
	pack.Reset();
	int giver, recipient;
	static char temp[64];
	giver = pack.ReadCell();
	recipient = pack.ReadCell();
	if (!IsValidEntity(giver) || !IsValidEntity(recipient))
		return Plugin_Handled;

	static char giverModel[31];
	GetEntPropString(giver, Prop_Data, "m_ModelName", giverModel, sizeof(giverModel));

	static char recipientModel[31];
	GetEntPropString(recipient, Prop_Data, "m_ModelName", recipientModel, sizeof(recipientModel));

	switch (recipientModel[29])
	{
		case NICK: // nick
			switch (giverModel[29])
			{
				case ROCHELLE:
					VocalizeScene(recipient, "scenes/gambler/thanksrochelle01");
				case COACH:
					VocalizeScene(recipient, "scenes/gambler/thankscoach01");
				case ELLIS:
					VocalizeScene(recipient, "scenes/gambler/thanksellis01");
				default:
				{
					int random = GetRandomInt(1, 5);
					Format(temp, sizeof(temp), "scenes/gambler/thanks0%i", random);
					VocalizeScene(recipient, temp);
				}
			}
		case ROCHELLE:
			switch (giverModel[29])
			{
				case NICK:
					VocalizeScene(recipient, "scenes/producer/thanksnick01");
				case COACH:
				{
					int random = GetRandomInt(1, 2);
					Format(temp, sizeof(temp), "scenes/producer/thankscoach0%i", random);
					VocalizeScene(recipient, temp);
				}
				case ELLIS:
					VocalizeScene(recipient, "scenes/producer/thanksellis01");
				default:
				{
					int random = GetRandomInt(1, 7);
					Format(temp, sizeof(temp), "scenes/producer/thanks0%i", random);
					VocalizeScene(recipient, temp);
				}
			}
		case COACH:
			switch (giverModel[29])
			{
				case NICK:
					VocalizeScene(recipient, "scenes/coach/thanksgambler01");
				case ROCHELLE:
					VocalizeScene(recipient, "scenes/coach/thanksproducer01");
				case ELLIS:
					VocalizeScene(recipient, "scenes/coach/thanksmechanic01");
				default:
				{
					int random = GetRandomInt(1, 9);
					Format(temp, sizeof(temp), "scenes/coach/thanks0%i", random);
					VocalizeScene(recipient, temp);
				}
			}
		case ELLIS:
			switch (giverModel[29])
			{
				case NICK:
				{
					int random = GetRandomInt(1, 3);
					Format(temp, sizeof(temp), "scenes/mechanic/thanksgambler0%i", random);
					VocalizeScene(recipient, temp);
				}
				case COACH:
				{
					int random = GetRandomInt(1, 4);
					Format(temp, sizeof(temp), "scenes/mechanic/thankscoach0%i", random);
					VocalizeScene(recipient, temp);
				}
				default:
				{
					int random = GetRandomInt(1, 6);
					Format(temp, sizeof(temp), "scenes/mechanic/thanks0%i", random);
					VocalizeScene(recipient, temp);
				}
			}
		case BILL:
		{
			int random = GetRandomInt(1, 11);
			if (random >= 10) {
    			Format(temp, sizeof(temp), "scenes/namvet/thanks%i", random);
			} else {
    			Format(temp, sizeof(temp), "scenes/namvet/thanks0%i", random);
			}
			VocalizeScene(recipient, temp);
		}
		case ZOEY:
			switch(giverModel[29])
			{
				case LOUIS:
				{
					int random = GetRandomInt(0, 6);
    				Format(temp, sizeof(temp), "scenes/teengirl/thanks%i", ZoeyThanksLouis[random]);
					VocalizeScene(recipient, temp);
				}
				case BILL:
				{
					int random = GetRandomInt(0, 1);
					if (ZoeyThanksBill[random] >= 10) {
    					Format(temp, sizeof(temp), "scenes/teengirl/thanks%i", ZoeyThanksBill[random]);
					} else {
    					Format(temp, sizeof(temp), "scenes/teengirl/thanks0%i", ZoeyThanksBill[random]);
					}
					VocalizeScene(recipient, temp);
				}
				case FRANCIS:
				{
					int random = GetRandomInt(0, 1);
					if (ZoeyThanksFrancis[random] >= 10) {
    					Format(temp, sizeof(temp), "scenes/teengirl/thanks%i", ZoeyThanksFrancis[random]);
					} else {
    					Format(temp, sizeof(temp), "scenes/teengirl/thanks0%i", ZoeyThanksFrancis[random]);
					}
					VocalizeScene(recipient, temp);
				}
				default:
				{
					int random = GetRandomInt(0, 18);
					if (ZoeyThanksGeneric[random] >= 10) {
    					Format(temp, sizeof(temp), "scenes/teengirl/thanks%i", ZoeyThanksGeneric[random]);
					} else {
    					Format(temp, sizeof(temp), "scenes/teengirl/thanks0%i", ZoeyThanksGeneric[random]);
					}
					VocalizeScene(recipient, temp);
				}
			}
		case FRANCIS:
			switch(giverModel[29])
			{
				case LOUIS:
				{
					int random = GetRandomInt(0, 1);
					Format(temp, sizeof(temp), "scenes/biker/thanks%i", FrancisThanksLouis[random]);
					VocalizeScene(recipient, temp);
				}
				case ZOEY:
				{
					Format(temp, sizeof(temp), "scenes/biker/thanks%i", Francis_ThanksZoey);
					VocalizeScene(recipient, temp);
				}
				case BILL:
				{
					Format(temp, sizeof(temp), "scenes/biker/thanks%i", Francis_ThanksBill);
					VocalizeScene(recipient, temp);
				}
				default:
				{
					int random = GetRandomInt(0, 14);
					if (FrancisThanksGeneric[random] >= 10) {
    					Format(temp, sizeof(temp), "scenes/biker/thanks%i", FrancisThanksGeneric[random]);
					} else {
    					Format(temp, sizeof(temp), "scenes/biker/thanks0%i", FrancisThanksGeneric[random]);
					}
					VocalizeScene(recipient, temp);
				}
			}
		case LOUIS:
			switch(giverModel[29])
			{
				case ZOEY:
				{
					Format(temp, sizeof(temp), "scenes/manager/thanks%i", Louis_ThanksZoey);
					VocalizeScene(recipient, temp);
				}
				default:
				{
					int random = GetRandomInt(0, 12);
					if (LouisThanksGeneric[random] >= 10) {
    					Format(temp, sizeof(temp), "scenes/manager/thanks%i", LouisThanksGeneric[random]);
					} else {
    					Format(temp, sizeof(temp), "scenes/manager/thanks0%i", LouisThanksGeneric[random]);
					}
					VocalizeScene(recipient, temp);
				}
			}

	}
	return Plugin_Handled;
}

// Taken from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// https://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
// ====================================================================================================
//					VOCALIZE SCENE
// ====================================================================================================
void VocalizeScene(int client, const char[] scenefile)
{
	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", scenefile);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}