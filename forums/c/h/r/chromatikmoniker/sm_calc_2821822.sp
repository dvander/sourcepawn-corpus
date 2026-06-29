#include <sourcemod>

Plugin myinfo =
{
    name = "Math Calculator",
    author = "Chromatik Moniker",
    description = "Calculates in all basic forms of math",
    version = "1.0",
    url = "N/A"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_calc", Command_Calculate, "Calculates basic arithmetic operations.");
}

public Action Command_Calculate(int client, int args)
{
    if (args < 3)
    {
        ReplyToCommand(client, "Usage: sm_calc <number1> <operation> <number2>");
        return Plugin_Handled;
    }

    char sNum1[64], sOperation[64], sNum2[64];
    float num1, num2, result;

    // Fetch the arguments
    GetCmdArg(1, sNum1, sizeof(sNum1));
    GetCmdArg(2, sOperation, sizeof(sOperation));
    GetCmdArg(3, sNum2, sizeof(sNum2));

    // Convert string arguments to floats
    num1 = StringToFloat(sNum1);
    num2 = StringToFloat(sNum2);

    // Determine the operation and calculate
    if (StrEqual(sOperation, "+"))
    {
        result = num1 + num2;
    }
    else if (StrEqual(sOperation, "-"))
    {
        result = num1 - num2;
    }
    else if (StrEqual(sOperation, "*"))
    {
        result = num1 * num2;
    }
    else if (StrEqual(sOperation, "/"))
    {
        if (num2 == 0.0)
        {
            ReplyToCommand(client, "Error: Division by zero.");
            return Plugin_Handled;
        }
        result = num1 / num2;
    }
    else
    {
        ReplyToCommand(client, "Invalid operation. Use +, -, *, or /.");
        return Plugin_Handled;
    }

    // Output the result
    ReplyToCommand(client, "Result: %.2f", result);
    return Plugin_Handled;
}