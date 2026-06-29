public OnPluginStart()  
{ 
    RegConsoleCmd("sm_rquit", Play_Sound); // type !sound in chat console
}

public Action:Play_Sound(client, args)
{
    //note - 'buttons' is folder where wav sound file is located
    ClientCommand(client, "play ragequit/ragequit.mp3"); // working example playing sound to client
	PrintToChatAll("RAGEQUIT");
    //ClientCommand(client, "play buttons/button14.wav"); // another sound
    //ClientCommand(client, "play UI/helpful_event_1.wav");  // another sound
    //ClientCommand(client, "play items/itempickup.wav");  // another sound
}  