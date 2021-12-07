#define MaxFileLength 251 // 255 - '.bsp'

public OnPluginStart()
{
   RegConsoleCmd("sm_request", Command_LogRequest);
   RegConsoleCmd("sm_ask", Command_LogAsk);
}

public Action:Command_LogRequest(client, args)
{
   if (args != 1)
   {
      ReplyToCommand(client, "[SM] Usage: sm_request <mapname>");
      return Plugin_Handled;
   }

   decl String:mapname[MaxFileLength];
   GetCmdArg(1, mapname, sizeof(mapname));

   LogMessage("%N requested map: %s", client, mapname);

   return Plugin_Handled;
}

public Action:Command_LogAsk(client, args)
{
   if (args < 1)
   {
      ReplyToCommand(client, "[SM] Usage: sm_ask <question>");
      return Plugin_Handled;
   }
   
   decl String:question[255];
   GetCmdArgString(question, sizeof(question));
   
   LogMessage("%N has asked: %s", client, question);
   
   return Plugin_Handled;
}