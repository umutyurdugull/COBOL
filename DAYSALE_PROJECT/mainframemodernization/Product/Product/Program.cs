
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using NetFrame.Extensions;
using NetFrame.Models;
using NetFrame.Services;
using System;
using System.Globalization;
using System.Threading.Tasks;

class Program
{
    static async Task Main(string[] args)
    {
        var services = new ServiceCollection();
        services.AddLogging(builder =>
        {
            builder.AddConsole();
            builder.SetMinimumLevel(LogLevel.Information);
        });

        var baseUrl = Environment.GetEnvironmentVariable("ZOSMF_BASE_URL");
        var username = Environment.GetEnvironmentVariable("ZOSMF_USERNAME"); 
        var password = Environment.GetEnvironmentVariable("ZOSMF_PASSWORD");

        if (string.IsNullOrWhiteSpace(baseUrl) || string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            Console.WriteLine("Missing ZOSMF configuration. Set ZOSMF_BASE_URL, ZOSMF_USERNAME, and ZOSMF_PASSWORD environment variables.");
            return;
        }

        baseUrl = baseUrl.Trim();
        if (!baseUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !baseUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            baseUrl = "https://" + baseUrl;
        }

        services.AddZosmf(options =>
        {
            options.BaseUrl = baseUrl;
            options.Username = username.Trim().ToUpper();
            options.Password = password;
            options.AllowInsecureConnections = true;
            options.PollingIntervalSeconds = 5;
            options.MaxPollingAttempts = 20;
        });

        var serviceProvider = services.BuildServiceProvider();
        var datasetService = serviceProvider.GetRequiredService<IDatasetService>();
        var jobService = serviceProvider.GetRequiredService<IJobService>();

        Console.WriteLine("=== NEW SALES RECORD ENTRY ===");

        Console.Write("Enter Customer ID (max 5 chars): ");
        string custInput = Console.ReadLine() ?? "";
        if (custInput.Length > 5) custInput = custInput.Substring(0, 5);
        string customerId = custInput.PadRight(5);

        Console.Write("Enter Category (max 10 chars): ");
        string catInput = Console.ReadLine() ?? "";
        if (catInput.Length > 10) catInput = catInput.Substring(0, 10);
        string category = catInput.ToUpper().PadRight(10); 

        Console.Write("Enter Quantity (0-999): ");
        if (!int.TryParse(Console.ReadLine(), out int quantity)) quantity = 0;
        string paddedQty = Math.Clamp(quantity, 0, 999).ToString("D3"); 

        Console.Write("Enter Unit Price (e.g. 150.50): ");
        string priceInput = Console.ReadLine() ?? "0";
        if (!decimal.TryParse(priceInput, NumberStyles.Any, CultureInfo.InvariantCulture, out decimal unitPrice))
            unitPrice = 0.00m;

        int priceAsInt = (int)Math.Round(unitPrice * 100);
        string paddedPrice = Math.Clamp(priceAsInt, 0, 999999).ToString("D6"); 

        string newRecord = $"{customerId}{category}{paddedQty}{paddedPrice}";
        Console.WriteLine($"\nFormatted Record: '{newRecord}' (Length: {newRecord.Length})");

        var salesDataset = $"{username.ToUpper()}.SALES.DAT";
        Console.WriteLine($"Retrieving dataset content from {salesDataset}...");

        string? currentData = await datasetService.RetrieveDatasetContentAsync(salesDataset);

        string normalizedCurrent = currentData?.Replace("\r\n", "\n").Replace("\r", "\n") ?? "";
        if (!normalizedCurrent.EndsWith("\n") && normalizedCurrent.Length > 0)
        {
            normalizedCurrent += "\n";
        }

        string updatedData = normalizedCurrent + newRecord + "\n";

        Console.WriteLine("Uploading updated sales data...");
        await datasetService.WriteDatasetContentAsync(salesDataset, null, updatedData);
        Console.WriteLine("Data successfully appended!");

        string localCblPath = System.IO.Path.Combine("..", "..", "..", "cblsrc", "DYSALE.cbl");
        if (System.IO.File.Exists(localCblPath))
        {
            Console.WriteLine($"Uploading COBOL source {localCblPath} to {username.ToUpper()}.CBL(DYSALE)...");
            var cblContent = await System.IO.File.ReadAllTextAsync(localCblPath);
            cblContent = cblContent.Replace("\r\n", "\n").Replace("\r", "\n");
            await datasetService.WriteDatasetContentAsync($"{username.ToUpper()}.CBL", "DYSALE", cblContent);
        }
        else
        {
            Console.WriteLine($"Warning: Local COBOL file {localCblPath} not found! Skipping source upload.");
        }

        Console.WriteLine("\nSubmitting JCL to run COBOL validation...");
        string jclContent =
$"//{username}J  JOB 1,NOTIFY=&SYSUID\n" +
$"//DELVAL   EXEC PGM=IEFBR14\n" +
$"//DD1      DD DSNAME={username}.VALID.DAT,DISP=(MOD,DELETE,DELETE),\n" +
$"//             UNIT=SYSALLDA,SPACE=(TRK,(1,1))\n" +
$"//COBRUN   EXEC IGYWCLG,SRC=DYSALE\n" +
$"//GO.SALES    DD DSNAME={username}.SALES.DAT,DISP=SHR\n" +
$"//GO.VALIDSAL DD DSNAME={username}.VALID.DAT,DISP=(NEW,CATLG,DELETE),\n" +
$"//             UNIT=SYSALLDA,SPACE=(TRK,(1,1)),\n" +
$"//             DCB=(RECFM=FB,LRECL=24,BLKSIZE=2400)\n" +
$"//GO.ERRORS   DD DSNAME={username}.ERROR.LOG,DISP=MOD\n" +
$"//GO.REPOUT   DD DSNAME={username}.REPORT,DISP=MOD\n" +
$"//GO.SORTWK01 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))\n" +
$"//GO.SORTWK02 DD UNIT=SYSALLDA,SPACE=(CYL,(1,1))\n";

        var submissionOptions = new JobSubmissionOptions { JclContent = jclContent };
        string jobResult = await jobService.SubmitJobAndWaitAsync(submissionOptions);
        Console.WriteLine("\n=== Mainframe Execution Completed ===");
        Console.WriteLine(jobResult);

        try
        {
            Console.WriteLine("\nRetrieving report from mainframe...");
            string? reportContent = await datasetService.RetrieveDatasetContentAsync($"{username.ToUpper()}.REPORT");
            if (!string.IsNullOrEmpty(reportContent))
            {
                Console.WriteLine("\n=== MAINFRAME REPORT ===");
                Console.WriteLine(reportContent);
            }

            Console.WriteLine("\nRetrieving error log from mainframe...");
            string? errorContent = await datasetService.RetrieveDatasetContentAsync($"{username.ToUpper()}.ERROR.LOG");
            if (!string.IsNullOrEmpty(errorContent))
            {
                Console.WriteLine("\n=== MAINFRAME ERROR.LOG ===");
                Console.WriteLine(errorContent);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: Failed to retrieve output files from mainframe: {ex.Message}");
        }
    }
}
