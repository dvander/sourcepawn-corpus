#pragma semicolon 1
#pragma newdecls required
#include <csgo_colors>

StringMap Stweap;
KeyValues kfg;
bool us;
Handle tim;
	
public Plugin myinfo =
{
	name = "Реклама",
	author = "Pheonix (˙·٠●Феникс●٠·˙)",
	version = "1.4",
	url = "http://zizt.ru/"
};

enum Rtupe
{
	V = 0,
	C,
	H,
	S,
	HUD
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("[Реклама] - плагин только для сервера CSGO");
	KFG_load();
	RegAdminCmd("sm_reklama_reload", Reload_cfg, ADMFLAG_ROOT);
}

public Action Reload_cfg(int iClient, int args)
{
	KFG_load();
	return Plugin_Handled;
}

void KFG_load()
{
	if(kfg) delete kfg;
	if(Stweap) delete Stweap;
	if(tim) delete tim;
	kfg = new KeyValues("Реклама");
	static char path[128], h[1024], buf[64];
	if(!path[0]) BuildPath(Path_SM, path, 128, "configs/reklama.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[Реклама] - Файл конфигураций не найден");
	else
	{
		kfg.Rewind();
		tim = CreateTimer(kfg.GetFloat("time"), rec, _, TIMER_REPEAT);
		kfg.JumpToKey("map");
		kfg.GotoFirstSubKey(false);
		Stweap = new StringMap();
		do
		{
			kfg.GetSectionName(h, 1024);
			kfg.GetString("", buf, 64);
			Stweap.SetString(h, buf);
		}
		while (kfg.GotoNextKey(false));
		kfg.Rewind();
		kfg.JumpToKey("text");
		kfg.GotoFirstSubKey();
		do
		{
			if(kfg.GetSectionName(h, 1024))
			{
				kfg.GetString("V", h, 1024);
				if(h[0])
				{
					Replese_constant(h, V);
					kfg.SetString("V", h);
				}
				kfg.GetString("C", h, 1024);
				if(h[0])
				{
					Replese_constant(h, C);
					kfg.SetString("C", h);
				}
				kfg.GetString("H", h, 1024);
				if(h[0])
				{
					Replese_constant(h, H);
					kfg.SetString("H", h);
				}
				kfg.GetString("S", h, 1024);
				if(h[0])
				{
					Replese_constant(h, S);
					kfg.SetString("S", h);
				}
				
				if(kfg.JumpToKey("HUD"))
				{
					kfg.GotoFirstSubKey();
					do
					{
						if(kfg.GetSectionName(h, 1024))
						{
							kfg.GetString("message", h, 1024);
							if(h[0])
							{
								Replese_constant(h, HUD);
								kfg.SetString("message", h);
							}
						}
					}
					while kfg.GotoNextKey();
					kfg.GoBack();
					kfg.GoBack();
				}
			}
		}
		while kfg.GotoNextKey();
		us = false;
	}
}

public Action rec(Handle timer)
{
	kvup();
	static char rkl[1024];
	rkl[0]='\0';
	kfg.GetString("V", rkl, 1024);
	if(rkl[0])
	{
		Replese_st(rkl);
		VotePrintAll(rkl);
	}
	rkl[0]='\0';
	kfg.GetString("C", rkl, 1024);
	if(rkl[0])
	{
		Replese_st(rkl);
		PrintCenterTextAll(rkl);
	}
	rkl[0]='\0';
	kfg.GetString("H", rkl, 1024);
	if(rkl[0])
	{
		Replese_st(rkl);
		PrintHintTextToAll(rkl);
	}
	rkl[0]='\0';
	kfg.GetString("S", rkl, 1024);
	if(rkl[0])
	{
		Replese_st(rkl);
		CGOPrintToChatAll(rkl);
	}
				
	if(kfg.JumpToKey("HUD"))
	{
		int channel;
		kfg.GotoFirstSubKey();
		do
		{
			if(kfg.GetSectionName(rkl, 1024))
			{
				channel = StringToInt(rkl);
				kfg.GetString("message", rkl, 1024);
				if(rkl[0])
				{
					Replese_st(rkl);
					SetHudTextParamsEx(kfg.GetFloat("x", -1.0), kfg.GetFloat("y", -1.0), kfg.GetFloat("holdtime", 5.0), KVGetColor4("color"), KVGetColor4("color2"), kfg.GetNum("effect"), kfg.GetFloat("fxtime"), kfg.GetFloat("fadein"), kfg.GetFloat("fadeout"));
					for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && !IsFakeClient(i)) ShowHudText(i, channel, rkl);
				}
			}
		}
		while kfg.GotoNextKey();
		
		kfg.GoBack();
		kfg.GoBack();
	}
	
	return Plugin_Continue;
}

int[] KVGetColor4(const char[] key)
{
	int color[4];
	kfg.GetColor4(key, color);
	return color;
}

void Replese_st(char[] rkl)
{
	char sText[256];
	if(StrContains(rkl, "{PL}") != -1)
	{
		IntToString(GetClientCount(), sText, sizeof(sText));//PL
		ReplaceString(rkl, 1024, "{PL}", sText);
	}
	if(StrContains(rkl, "{MAP}") != -1)
	{
		GetCurrentMap(sText, sizeof(sText));//MAP
		Stweap.GetString(sText, sText, sizeof(sText));
		ReplaceString(rkl, 1024, "{MAP}", sText);
	}
	if(StrContains(rkl, "{TIME}") != -1)
	{
		FormatTime(sText, sizeof(sText), "%H:%M:%S");//TIME
		ReplaceString(rkl, 1024, "{TIME}", sText);
	}
	if (StrContains(rkl, "{TIMELEFT}") != -1)
	{
		int timeleft;
		if (GetMapTimeLeft(timeleft) && timeleft > 0)
		{
			Format(sText, sizeof(sText), "%d:%02d", timeleft / 60, timeleft % 60);
			ReplaceString(rkl, 1024, "{TIMELEFT}", sText);
		}
		else ReplaceString(rkl, 1024, "{TIMELEFT}", "0");
	}
	if(StrContains(rkl, "{DATE}") != -1)
	{
		FormatTime(sText, sizeof(sText), "%d/%m/%Y");
		ReplaceString(rkl, 1024, "{DATE}", sText);
	}
	if(StrContains(rkl, "{MAXPL}") != -1)
	{
		IntToString(GetMaxHumanPlayers(), sText, sizeof(sText));
		ReplaceString(rkl, 1024, "{MAXPL}", sText);
	}
	if(StrContains(rkl, "{NEXTMAP}") != -1)
	{
		GetNextMap(sText, sizeof(sText));
		ReplaceString(rkl, 1024, "{NEXTMAP}", sText);
	}
	if(StrContains(rkl, "{ADMINSONLINE1}") != -1)
	{
		sText[0]='\0';
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && !IsFakeClient(i) && GetUserFlagBits(i) & ADMFLAG_GENERIC)
		{
			if(!sText[0]) GetClientName(i, sText, sizeof(sText));
			else Format(sText, sizeof(sText), "%s, %N", sText, i);
		}
		if(!sText[0]) sText = "SERVER";
		ReplaceString(rkl, 1024, "{ADMINSONLINE1}", sText);
	}
	if(StrContains(rkl, "{ADMINSONLINE2}") != -1)
	{
		sText[0]='\0';
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && !IsFakeClient(i) && GetUserFlagBits(i) & ADMFLAG_GENERIC)
		{
			if(!sText[0]) GetClientName(i, sText, sizeof(sText));
			else Format(sText, sizeof(sText), "%s\n%N", sText, i);
		}
		if(!sText[0]) sText = "SERVER";
		ReplaceString(rkl, 1024, "{ADMINSONLINE2}", sText);
	}
}

void Replese_constant(char[] rkl, Rtupe tupe)
{
	ReplaceString(rkl, 1024, "\\n", "\n");
	char sText[4][128];
	if(!sText[0][0])
	{
		int ip = FindConVar("hostip").IntValue;
		FormatEx(sText[0], 128, "%d.%d.%d.%d", ip >>> 24 & 255, ip >>> 16 & 255, ip >>> 8 & 255, ip & 255); //IP
		GetConVarString(FindConVar("hostport"), sText[1], 128); //PORT
		IntToString(RoundToZero(1.0/GetTickInterval()), sText[2], 128);//TIC
		GetConVarString(FindConVar("hostname"), sText[3], 128); //SERVERNAME
	}
	ReplaceString(rkl, 1024, "{IP}", sText[0]);
	ReplaceString(rkl, 1024, "{PORT}", sText[1]);
	ReplaceString(rkl, 1024, "{TIC}", sText[2]);
	ReplaceString(rkl, 1024, "{SERVERNAME}", sText[3]);
	switch (tupe)
	{
		case C: CGOReplaceColorCsay(rkl, 1024);
		case H: CGOReplaceColorHsay(rkl, 1024);
		case S: CGOReplaceColorSay(rkl, 1024);
	}
}

void VotePrintAll(const char[] tx)
{
	Protobuf v = view_as<Protobuf>(StartMessageAll("VotePass", USERMSG_RELIABLE));
	v.SetInt("team", -1);
	v.SetString("disp_str", "#SFUI_Scoreboard_NormalPlayer");
	v.SetString("details_str", tx);
	v.SetInt("vote_type", 0);
	EndMessage();
}

void kvup()
{
	if(!us)
	{
		kfg.Rewind();
		kfg.JumpToKey("text");
		kfg.GotoFirstSubKey();
		us = true;
		return;
	}
	if(kfg.GotoNextKey()) return;
	else
	{
		kfg.Rewind();
		kfg.JumpToKey("text");
		kfg.GotoFirstSubKey();
		return;
	}
}