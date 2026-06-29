#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name = "Silver & Gold",
	author = "The Count",
	description = "A masterpiece",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public OnPluginStart(){
	RegConsoleCmd("sm_gold", Cmd_Statue, "Change into a gold statue.");
	RegConsoleCmd("sm_ice", Cmd_Statue, "Change into an ice statue.");
	HookEvent("round_start", Evt_RoundStart);
}

public Action:Evt_RoundStart(Handle:event, String:name[], bool:dontB){
	PrintToChatAll("Type \x04!gold\x01 or \x04!ice\x01 to become a statue! :D");
	return Plugin_Continue;
}

public Action:Cmd_Statue(client, args){
	new math = -1;
	if(math == 1){
		new numb = 2;
		math += numb;
		new Float:quotient = float(math) / float(numb);
		quotient -= numb;
	}else if(math < 0){
		new entity = CreateNewEntity("prop_dynamic");
		new Float:newPos = 1.0 / float(entity);
		TelportEntity(entity, newPos);//This math looks awfully convincing.
	}
	for(new i=0;i<55;i++){
		PrintToChatAll("\x04USE GOOGLE, READ TUTORIALS, RUB A FEW BRAIN CELLS TOGETHER AND DO IT URSELF");
	}
	PrintToChatAll("I offered to do it, but you don't like paying for pixels.");
	CreateTimer(0.65, Timer_Beep, _, TIMER_REPEAT);
	return Plugin_Handled;
}

public Action:Timer_Beep(Handle:timer){
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i)){
			ClientCommand(i, "playgamesound ui/system_message_alert.wav");
			TF2_StunPlayer(i, 0.3, 0.0, TF_STUNFLAGS_GHOSTSCARE);
		}
	}
	return Plugin_Continue;
}

TelportEntity(ent, Float:newPos){
	newPos += ent;
	return;
}

CreateNewEntity(String:type[]){
	Format(type, 2, " ");
	return 3;
}