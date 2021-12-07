#pragma semicolon 1

#include <sourcemod>
#define TIMER_INTERVAL 60.0

new Handle:sv_password;
//new String:listOfChar[] = "aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ0123456789";
new String:listOfChar[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
new Handle:passwordChangeTimer = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "Random Server Password",
	author = "glub, with snippets by Xsinthis`",
	description = "Randomly generates a server password and resets it once server is empty",
	version = "1.2nt",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_newpassword", GeneratePassword, ADMFLAG_BAN, "Randomly generates a password for the server");
	sv_password = FindConVar("sv_password");
//	CreateTimer(5.0, CheckEmpty, 0, TIMER_REPEAT );
}


public OnClientConnected(client)
{
  // Check if the Timer is still a valid timer.
  if (passwordChangeTimer != INVALID_HANDLE)
  {
    // Stop countdown! Kill the timer! We have a customer!
    PrintToServer("Kill timer, we have a customer");
//    KillTimer(passwordChangeTimer);
    passwordChangeTimer = INVALID_HANDLE;
  }
}

public OnClientDisconnect(client)
{
	if(IsServerEmpty){
	passwordChangeTimer = CreateTimer(TIMER_INTERVAL, CheckEmpty);
	}
}


public IsServerEmpty()
{
  for(new i=1; i<GetMaxClients(); i++){
    if( IsClientInGame(i) && !IsFakeClient(i) ){ // human player & in game
      return false;
    }
  }
  return true;
}

public Action:CheckEmpty( Handle:timer, any:ignore ) {
	// Is the server empty? if so, resets password to specified value
	for( new i = 1; i <= MaxClients; i++ ) {
		if( IsClientConnected( i ) && !IsFakeClient( i ) ) {
			return;
		}
	}
	new String:defaultpassword[] = "";
	SetConVarString(sv_password, defaultpassword);
	LogMessage( "Server is empty, resetting default password" );
	PrintToServer("Changed the server password to default");
	KillTimer(passwordChangeTimer);
}

public Action:GeneratePassword(client, args)
{
	new String:password[5];
	new String:password1[5];
	new String:password2[5];
	new String:password3[5];
	new String:password4[5];

	for(new i = 1; i <= 7; i++)   // 7 passes anyone?
	{
        new randomInt = GetRandomInt(0, 26);
        new randomInt1 = GetRandomInt(0, 26);
        new randomInt2 = GetRandomInt(0, 26);
        new randomInt3 = GetRandomInt(0, 26);
        StrCat(password1, 2, listOfChar[randomInt1]);
        StrCat(password2, 2, listOfChar[randomInt2]);
        StrCat(password3, 2, listOfChar[randomInt3]);
        StrCat(password4, 2, listOfChar[randomInt]);		
		
        StrCat(password1, 4, password2);
        StrCat(password1, 4, password3);
        StrCat(password1, 5, password4);

        strcopy(password, sizeof(password), password1);  // I know that is sort of useless
        //StrCat(password, sizeof(password), password4); //deprecated
        //new pw_int = GetRandomInt(100, 999);  //for a number version
        //IntToString(pw_int, password, 4);
	}
    
	SetConVarString(sv_password, password);
    
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	PrintToChatAll("---------------------------------------------------------------------");
	PrintToChatAll("%s changed the server password to: %s", name, password);
	PrintToChatAll("---------------------------------------------------------------------");
	PrintToServer("%s changed the server password to: %s", name, password);
//	PrintToConsole(client, "password1 changed to: %s", password1);  just debugging silly code here
//	PrintToConsole(client, "password2 changed to: %s", password2);
//	PrintToConsole(client, "password3 changed to: %s", password3);
//	PrintToConsole(client, "password4 changed to: %s", password4);
	PrintToConsole(client, "==================================");
	PrintToConsole(client, "Server password changed to: %s", password);
	PrintToConsole(client, "==================================");
	LogMessage("%s changed the server password to: %s", name, password);
}