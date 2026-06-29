#include <files>

ArrayList colors;
bool isadmin[66];
char CTeamColors[][] = { "\x07CCCCCC", "\x07FF4040", "\x0799CCFF" };

#define MAXCOLOR_NAME 64

public void OnPluginStart()
{
	colors = new ArrayList(ByteCountToCells(MAXCOLOR_NAME));

	char buffer[128];
	BuildPath( Path_SM, buffer, sizeof buffer , "configs/color_tags.ini"); 
	File file = OpenFile(buffer, "r");
	if(file)
    {
		while( !file.EndOfFile() )
		{
			file.ReadLine( buffer, sizeof buffer );
			for(int i = 0; i < sizeof(buffer);i++)
			{
				if(buffer[i] == ' ')
				{
					buffer[i] = 0;
					buffer[i+8] = 0;
					colors.PushString(buffer);
					colors.PushString(buffer[i+1]);
					break;
				}
			}
		}
		file.Close();
	}

	int i = MaxClients;
	while(--i)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
	RegConsoleCmd("sm_colors", PrintColors);
}

Action PrintColors(int client, int args = 0)
{
	char all_colors[255],buffer[MAXCOLOR_NAME],hexcode[16];
	int len = colors.Length-1;
	while( len >= 0 )
	{
		colors.GetString( len , hexcode, sizeof hexcode);
		colors.GetString( len-1 , buffer, sizeof buffer);
		Format(all_colors,sizeof all_colors,"%s %s%s",all_colors,hexcode,buffer);

		if(strlen(all_colors) > 200)
		{
			ReplaceString( all_colors , sizeof all_colors , "#", "\x07" , false);		
			PrintToChat(client,"\x01%s",all_colors);
			all_colors[0] = 0;
		}
		len -= 2;
	}

	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
	{
		int flags = GetUserFlagBits(client);
		isadmin[client] = ( flags & ADMFLAG_CUSTOM2 ) != 0 || (flags & ADMFLAG_ROOT ) != 0;
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!isadmin[client])
	{
		return Plugin_Continue;
	}

	int textlen = strlen(sArgs),len,i;

	char chat_text[512];
	strcopy(chat_text, sizeof chat_text, sArgs);

	i = textlen;
	while(i--)
	{
		if( chat_text[i] == '{' || chat_text[i] == '}' )
		{
			len = colors.Length-1;
			break;
		}
	}

	if( len == 0)
		return Plugin_Continue;	

	char buffer[MAXCOLOR_NAME],hexcode[16];

	while( len >= 0 )
	{
		colors.GetString( len , hexcode, sizeof hexcode);
		colors.GetString( len-1 , buffer, sizeof buffer);
		ReplaceString( chat_text , sizeof chat_text , buffer, hexcode , false);
		len -= 2;
	}
	ReplaceString( chat_text , sizeof chat_text , "#", "\x07" , false);

	int team = GetClientTeam(client);
	bool forteam = strcmp(command,"say_team") == 0;

	char gbuffer[512];
	Format(gbuffer,sizeof gbuffer,"\x01%s%s%s%N \x01: %s",IsPlayerAlive(client) ? "":"*DEAD* ",forteam ? "(TEAM) ":NULL_STRING,CTeamColors[team-1],client,chat_text);

	i = MaxClients;

	while(--i)
	{
		if( IsClientInGame(i) )
		{
			if(forteam)
			{
				if(GetClientTeam(i) == team)
					PrintToChat(i,gbuffer);
			}
			else
				PrintToChat(i,gbuffer);
		}
	}

	return Plugin_Handled;
}