#pragma newdecls required 
#pragma semicolon 1 

public Plugin myinfo = 
{
    name = "[TF2] Voice Command Anti-Anti-Spam",
    author = "Sappykun",
    description = "Patches out the voice command spam control added in 2018",
    version = "1.0",
    url = "https://weea.boutique/"
};

public void OnPluginStart()
{
    Handle hConfig = LoadGameConfigFile("voicespampatch");
    
    if (hConfig == INVALID_HANDLE)
        SetFailState("Could not load gamedata/voicespampatch.txt");
    
    Address addrNoteSpokeVoiceCommand = GameConfGetAddress(hConfig, "NoteSpokeVoiceCommand");
    int offsetVoiceSpamCounter = GameConfGetOffset(hConfig, "m_iVoiceSpamCounter");
    
    CloseHandle(hConfig);
    
    // There's a spam prevention feature added in 2018 that will increase the
    // voice command delay if you try to use them too often. Spamming voice
    // commands increments a value called m_iVoiceSpamCounter that adds more
    // delay to the next time the server will let you use a voice command.
    // We're just setting the instruction (add 1 to m_iVoiceSpamCounter) to
    // add 0 instead, effectively no-oping it.
    
    int currentValue = LoadFromAddress(addrNoteSpokeVoiceCommand + view_as<Address>(offsetVoiceSpamCounter), NumberType_Int8);
    if (currentValue != 1)
        SetFailState("Expected byte (0x00000001) was actually %X! The gamedata must be out of date.", currentValue);

    StoreToAddress(addrNoteSpokeVoiceCommand + view_as<Address>(offsetVoiceSpamCounter), 0x00, NumberType_Int8);
    
    // Remove the arbitrary 0.1 minimum added in 2017
    
    Handle maxVoiceSpeakCvar = FindConVar("tf_max_voice_speak_delay");
	
    if (maxVoiceSpeakCvar != INVALID_HANDLE)
        SetConVarBounds(maxVoiceSpeakCvar, ConVarBound_Lower, true, -1.0);

    CloseHandle(maxVoiceSpeakCvar);
}
