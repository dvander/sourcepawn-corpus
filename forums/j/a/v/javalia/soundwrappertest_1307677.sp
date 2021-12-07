#include <sourcemod>
#include <sdktools>
#include <SoundWrapper>

#pragma semicolon 1

new const String:PluginVersion[60] = "1.0.0.3";

public Plugin:myinfo = {
	
	name = "swtest",
	author = "javalia",
	description = "test",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
	
};

public OnPluginStart(){
	
	RegConsoleCmd("sm_ts", command_test1);
	RegConsoleCmd("sm_ts2", command_test2);
	RegConsoleCmd("sm_startloop1", command_test3);
	RegConsoleCmd("sm_endloop", command_test4);
	RegConsoleCmd("sm_startloop", command_test5);
	RegConsoleCmd("sm_deletesound", command_test6);
	RegConsoleCmd("sm_deletesound1", command_test7);
	RegConsoleCmd("sm_deletesound2", command_test8);
	
}

public SWRegistSoundOnMapStart(){

	SW_RegSound("testsound1", "npc/roller/mine/rmine_blades_out1.wav");
	SW_RegSound("testsound1", "npc/roller/mine/rmine_blades_out2.wav");
	SW_RegSound("testsound1", "npc/roller/mine/rmine_blades_out3.wav");
	SW_RegSound("testsound1", "npc/roller/mine/rmine_blades_in1.wav");
	SW_RegSound("testsound1", "npc/roller/mine/rmine_blades_in2.wav");
	SW_RegSound("testsound1", "npc/roller/mine/rmine_blades_in3.wav");
	
	SW_RegSound("testsound12", "npc/roller/mine/rmine_blades_out1.wav");
	SW_RegSound("testsound12", "npc/roller/mine/rmine_blades_out2.wav");
	SW_RegSound("testsound12", "npc/roller/mine/rmine_blades_out3.wav");
	SW_RegSound("testsound12", "npc/roller/mine/rmine_blades_in1.wav");
	SW_RegSound("testsound12", "npc/roller/mine/rmine_blades_in2.wav");
	SW_RegSound("testsound12", "npc/roller/mine/rmine_blades_in3.wav");
	
	SW_RegSound("testsound13", "npc/roller/mine/rmine_blades_out1.wav");
	SW_RegSound("testsound13", "npc/roller/mine/rmine_blades_out2.wav");
	SW_RegSound("testsound13", "npc/roller/mine/rmine_blades_out3.wav");
	SW_RegSound("testsound13", "npc/roller/mine/rmine_blades_in1.wav");
	SW_RegSound("testsound13", "npc/roller/mine/rmine_blades_in2.wav");
	SW_RegSound("testsound13", "npc/roller/mine/rmine_blades_in3.wav");
	
	SW_RegSound("testsound14", "npc/roller/mine/rmine_blades_out1.wav");
	SW_RegSound("testsound14", "npc/roller/mine/rmine_blades_out2.wav");
	SW_RegSound("testsound14", "npc/roller/mine/rmine_blades_out3.wav");
	SW_RegSound("testsound14", "npc/roller/mine/rmine_blades_in1.wav");
	SW_RegSound("testsound14", "npc/roller/mine/rmine_blades_in2.wav");
	SW_RegSound("testsound14", "npc/roller/mine/rmine_blades_in3.wav");
	
	SW_RegSound("numbercall", "hl1/fvox/ten.wav");
	SW_RegSound("numbercall", "hl1/fvox/twenty.wav");
	SW_RegSound("numbercall", "hl1/fvox/thirty.wav");
	SW_RegSound("numbercall", "hl1/fvox/fourty.wav");
	SW_RegSound("numbercall", "hl1/fvox/fifty.wav");
	SW_RegSound("numbercall", "hl1/fvox/sixty.wav");
	SW_RegSound("numbercall", "hl1/fvox/seventy.wav");
	SW_RegSound("numbercall", "hl1/fvox/eighty.wav");
	SW_RegSound("numbercall", "hl1/fvox/ninety.wav");
	SW_RegSound("numbercall", "hl1/fvox/onehundred.wav");
	
	SW_RegSound("numbercall2", "hl1/fvox/ten.wav");
	SW_RegSound("numbercall2", "hl1/fvox/twenty.wav");
	SW_RegSound("numbercall2", "hl1/fvox/thirty.wav");
	SW_RegSound("numbercall2", "hl1/fvox/fourty.wav");
	SW_RegSound("numbercall2", "hl1/fvox/fifty.wav");
	SW_RegSound("numbercall2", "hl1/fvox/sixty.wav");
	SW_RegSound("numbercall2", "hl1/fvox/seventy.wav");
	SW_RegSound("numbercall2", "hl1/fvox/eighty.wav");
	SW_RegSound("numbercall2", "hl1/fvox/ninety.wav");
	SW_RegSound("numbercall2", "hl1/fvox/onehundred.wav");
	
	SW_RegSound("numbercall3", "hl1/fvox/ten.wav");
	SW_RegSound("numbercall3", "hl1/fvox/twenty.wav");
	SW_RegSound("numbercall3", "hl1/fvox/thirty.wav");
	SW_RegSound("numbercall3", "hl1/fvox/fourty.wav");
	SW_RegSound("numbercall3", "hl1/fvox/fifty.wav");
	SW_RegSound("numbercall3", "hl1/fvox/sixty.wav");
	SW_RegSound("numbercall3", "hl1/fvox/seventy.wav");
	SW_RegSound("numbercall3", "hl1/fvox/eighty.wav");
	SW_RegSound("numbercall3", "hl1/fvox/ninety.wav");
	SW_RegSound("numbercall3", "hl1/fvox/onehundred.wav");
	
	SW_RegSound("numbercall4", "hl1/fvox/ten.wav");
	SW_RegSound("numbercall4", "hl1/fvox/twenty.wav");
	SW_RegSound("numbercall4", "hl1/fvox/thirty.wav");
	SW_RegSound("numbercall4", "hl1/fvox/fourty.wav");
	SW_RegSound("numbercall4", "hl1/fvox/fifty.wav");
	SW_RegSound("numbercall4", "hl1/fvox/sixty.wav");
	SW_RegSound("numbercall4", "hl1/fvox/seventy.wav");
	SW_RegSound("numbercall4", "hl1/fvox/eighty.wav");
	SW_RegSound("numbercall4", "hl1/fvox/ninety.wav");
	SW_RegSound("numbercall4", "hl1/fvox/onehundred.wav");
	
	SW_RegSound("numbercall5", "hl1/fvox/ten.wav");
	SW_RegSound("numbercall5", "hl1/fvox/twenty.wav");
	SW_RegSound("numbercall5", "hl1/fvox/thirty.wav");
	SW_RegSound("numbercall5", "hl1/fvox/fourty.wav");
	SW_RegSound("numbercall5", "hl1/fvox/fifty.wav");
	SW_RegSound("numbercall5", "hl1/fvox/sixty.wav");
	SW_RegSound("numbercall5", "hl1/fvox/seventy.wav");
	SW_RegSound("numbercall5", "hl1/fvox/eighty.wav");
	SW_RegSound("numbercall5", "hl1/fvox/ninety.wav");
	SW_RegSound("numbercall5", "hl1/fvox/onehundred.wav");
	
	SW_RegSound("loop1", "weapons/physcannon/hold_loop.wav", _, _, SND_STOP);
	SW_RegSound("loop1", "npc/scanner/combat_scan_loop6.wav", _, _, SND_STOP);

}

public Action:command_test1(client, args){
	
	SW_PlaySoundToAll("testsound1");
	
	return Plugin_Handled;
	
}

public Action:command_test2(client, args){
	
	SW_PlaySoundToAll("numbercall");
	
	return Plugin_Handled;
	
}

public Action:command_test3(client, args){
	
	SW_PlaySoundToAll("loop1", client);
	
	return Plugin_Handled;
	
}

public Action:command_test4(client, args){
	
	SW_StopSound(client, "loop1");
	
	return Plugin_Handled;
	
}

public Action:command_test5(client, args){
	
	SW_PlaySoundToAll("loop", client);
	
	return Plugin_Handled;
	
}

public Action:command_test6(client, args){
	
	SW_DeleteSound("numbercall5", "hl1/fvox/onehundred.wav");
	
	return Plugin_Handled;
	
}

public Action:command_test7(client, args){
	
	SW_DeleteSound("numbercall5", "hl1/fvox/ten.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/twenty.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/thirty.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/fourty.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/fifty.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/sixty.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/seventy.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/eighty.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/ninety.wav");
	SW_DeleteSound("numbercall5", "hl1/fvox/onehundred.wav");
	
	return Plugin_Handled;
	
}

public Action:command_test8(client, args){
	
	SW_DeleteSound("numbercall5");
	
	return Plugin_Handled;
	
}