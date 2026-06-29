//AlliedModders - 101 - 

#include <sdktools_voice>
#define Type_Of_Printing	1

new Handle: h_timer;
new speakers;
bool Is_Spk[MAXPLAYERS+1],IsMuted[MAXPLAYERS+1];
char P_Name[MAXPLAYERS+1][34];
char S_Text[512];

public void BaseComm_OnClientMute(int P, bool mute)
{
    if(mute)
    {
        if (Is_Spk[P])OnClientSpeakingEnd(P);
		IsMuted[P]=true ;
    }
    else    IsMuted[P]=false;
} 

public void OnClientSpeaking(P)
{
	if (IsMuted[P]) return ;
	if (!Is_Spk[P])
	{
		speakers++;
		Is_Spk[P]=true;
		if (h_timer==INVALID_HANDLE)
		{
			Format(S_Text,512,"\nSpeakers List :\n");
			h_timer=CreateTimer(1.8,Timer_Text_Reviver,_,TIMER_REPEAT);
		}
		Format(P_Name[P],34,"%N\n",P);
		StrCat(S_Text,512,P_Name[P]);
		Print_Text_To_All();
		//PrintToChat(P,"OnClientSpeaking >> speakers=%d",speakers);
	}
}

public void OnClientSpeakingEnd(P)
{
	if (IsMuted[P]) return ;
	Is_Spk[P]=false;
	ReplaceString(S_Text,512,P_Name[P],"",true);
	if (--speakers==0)
	{
		Format(S_Text,512,"");
		delete h_timer;
	}
	Print_Text_To_All();
	//PrintToChat(P,"OnClientSpeakingEnd >> speakers=%d",speakers);
}

public void OnClientDisconnect(P)
{
	if (Is_Spk[P])OnClientSpeakingEnd(P);
	IsMuted[P]=false;
}

public Action Timer_Text_Reviver(Handle timer)
{
	Print_Text_To_All();
	return Plugin_Continue;
}

Print_Text_To_All()
{
	for(int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			//if (Client disabled show msg by /nolist) continue;
			
			switch(Type_Of_Printing)	
			{
				case 1 :PrintCenterText(i,S_Text);
				case 2 :PrintToConsole(i,S_Text);
				case 3 :DisplayPanelTo(i);
			}
		}
	}
}

DisplayPanelTo(P)
{
	new Handle:C_P=CreateMenu(CP);
    SetMenuTitle(C_P,S_Text);
    AddMenuItem(C_P,"Fake","Close",ITEMDRAW_SPACER);
    DisplayMenu(C_P,P,3);	//panel life time is 3 seconds , revived by timer .
	//in case u removed timer edit to: DisplayMenu(C_P,P,speakers?60:1);
}

public CP(Handle:h1,MenuAction:a,P,itemnum)
{
    if (a==MenuAction_End)delete h1; 
}
