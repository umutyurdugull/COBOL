using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using NetFrame.Models;
using NetFrame.Services;
using NetFrame.Extensions;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace DAYSALE
{
    public class Program
    {
        static async Task Main(string[] args)
        {
            string zosmfURL = "https://204.90.115.200:10443";
            string dbURL = "http://204.90.115.200:5040";
            string username = "Z88116";
            string password = "";
            string dbName = "";

            var services = new ServiceCollection();
            services.AddLogging(builder =>
            {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Warning);
            });

            services.AddZosmf(options =>
            {
                options.BaseUrl = zosmfURL;
                options.Username = username;
                options.Password = password;
                options.AllowInsecureConnections = true;
            });

            
            services.Configure<Db2Config>(options =>
            {
                options.BaseUrl = dbURL;
                options.AllowInsecureConnections = true;
                options.Username = username;
                options.Password = password;
                options.DatabaseName = dbName;
            });

            services.AddHttpClient<IDb2RestService, Db2RestService>((serviceProvider, client) =>
            {
                var config = serviceProvider.GetRequiredService<IOptions<Db2Config>>().Value;
                client.BaseAddress = new Uri(config.BaseUrl);
            })
            .ConfigurePrimaryHttpMessageHandler((serviceProvider) =>
            {
                var config = serviceProvider.GetRequiredService<IOptions<Db2Config>>().Value;
                var handler = new HttpClientHandler();
                if (config.AllowInsecureConnections)
                {
                    handler.ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
                }
                return handler;
            });

            var serviceProvider = services.BuildServiceProvider();
            var db2Service = serviceProvider.GetRequiredService<IDb2RestService>();
            var datasetService = serviceProvider.GetRequiredService<IDatasetService>();
            var jobService = serviceProvider.GetRequiredService<IJobService>();
            await RunSqlViaJclAsync(jobService, username);
            
        }

        

        

        static async Task RunSqlViaJclAsync(IJobService jobService, string username)
        {
            Console.Clear();
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("=== Run SQL via Batch JCL (DSNTEP2 / DSNTEP4 / DSNTIAD) ===");
            Console.ResetColor();

            Console.WriteLine("Choose DB2 Utility Program:");
            Console.WriteLine("1. DSNTEP2 (Supports SELECT and non-SELECT) [Recommended]");
            Console.WriteLine("2. DSNTEP4 (Supports SELECT and non-SELECT, multi-row fetch)");
            Console.WriteLine("3. DSNTIAD (Supports non-SELECT statements only)");
            Console.Write("Choice (1-3): ");
            var progChoice = Console.ReadLine();

            string progName = "DSNTEP2";
            string defaultPlan = "DSNTEPD1";
            bool isSelectAllowed = true;

            if (progChoice == "2")
            {
                progName = "DSNTEP4";
                defaultPlan = "DSNTEPD1";
            }
            else if (progChoice == "3")
            {
                progName = "DSNTIAD";
                defaultPlan = "DSNTIAD1";
                isSelectAllowed = false;
            }

            Console.Write($"Enter Plan Name (Default: {defaultPlan}): ");
            var planName = Console.ReadLine();
            if (string.IsNullOrWhiteSpace(planName))
            {
                planName = defaultPlan;
            }

            Console.WriteLine($"\nEnter your SQL statement (Default: {(isSelectAllowed ? "SELECT * FROM IBMUSER.EMP FETCH FIRST 5 ROWS ONLY" : "INSERT INTO IBMUSER.EMP (EMPNO, FIRSTNME, LASTNAME, DEPTNO) VALUES ('999999', 'TEST', 'USER', 'A00')")}):");
            var sqlQuery = Console.ReadLine();
            if (string.IsNullOrWhiteSpace(sqlQuery))
            {
                sqlQuery = isSelectAllowed ? "SELECT * FROM IBMUSER.EMP;" : "INSERT INTO IBMUSER.EMP (EMPNO, FIRSTNME, LASTNAME, DEPTNO) VALUES ('999999', 'TEST', 'USER', 'A00');";
            }

            if (!sqlQuery.TrimEnd().EndsWith(";"))
            {
                sqlQuery = sqlQuery.TrimEnd() + ";";
            }

            Console.WriteLine("\nSubmitting SQL Job to mainframe...");

            // Add alignment parameters if running DSNTEP2 or DSNTEP4
            string runParams = (progName == "DSNTEP2" || progName == "DSNTEP4") 
                ? " PARMS('/ALIGN(MID)')" 
                : "";

            // Format SQL query to split long statements into multiple lines under 72 chars
            string formattedSql = FormatSqlForJcl(sqlQuery);
            
            string jclContent = 
                $"//{username}S JOB 1,NOTIFY={username}\n" +
                $"//STEP1    EXEC PGM=IKJEFT01\n" +
                $"//STEPLIB  DD DISP=SHR,DSN=DSND10.SDSNLOAD\n" +
                $"//SYSPRINT DD SYSOUT=*\n" +
                $"//SYSTSPRT DD SYSOUT=*\n" +
                $"//SYSUDUMP DD SYSOUT=*\n" +
                $"//SYSTSIN  DD *\n" +
                $"  DSN SYSTEM(DBDG)\n" +
                $"  RUN PROGRAM({progName}) PLAN({planName}) +\n" +
                $"      LIB('DSND10.DBDG.RUNLIB.LOAD'){runParams}\n" +
                $"  END\n" +
                $"/*\n" +
                $"//SYSIN    DD *\n" +
                $"{formattedSql}\n" +
                $"/*\n";

            try
            {
                var jobOptions = new JobSubmissionOptions
                {
                    JclContent = jclContent
                };

                var jobStatus = await jobService.SubmitJobAndWaitAsync(jobOptions);
                
                var jobNode = System.Text.Json.Nodes.JsonNode.Parse(jobStatus);
                string? jobName = jobNode?["jobname"]?.ToString();
                string? jobId = jobNode?["jobid"]?.ToString();

                if (string.IsNullOrEmpty(jobName) || string.IsNullOrEmpty(jobId))
                {
                    Console.WriteLine("Could not retrieve job name or ID from status response.");
                    Console.WriteLine(jobStatus);
                }
                else
                {
                    Console.WriteLine($"\nJob Completed: {jobName} ({jobId})");
                    Console.WriteLine("Fetching output logs...");

                    var jobFiles = await jobService.ListJobFilesAsync(jobName, jobId);
                    var sysTsPrtFile = jobFiles.Find(f => f.DdName == "SYSTSPRT");
                    var sysPrintFile = jobFiles.Find(f => f.DdName == "SYSPRINT");

                    if (sysTsPrtFile != null && sysTsPrtFile.Id.HasValue)
                    {
                        var tsPrtContent = await jobService.GetJobFileRecordsAsync(jobName, jobId, sysTsPrtFile.Id.Value.ToString());
                        Console.WriteLine("\n=================== TSO SESSION (SYSTSPRT) ===================");
                        Console.WriteLine(tsPrtContent);
                        Console.WriteLine("==============================================================");
                    }

                    if (sysPrintFile != null && sysPrintFile.Id.HasValue)
                    {
                        var printContent = await jobService.GetJobFileRecordsAsync(jobName, jobId, sysPrintFile.Id.Value.ToString());
                        Console.WriteLine("\n=================== SQL OUTPUT (SYSPRINT) ===================");
                        Console.WriteLine(printContent);
                        Console.WriteLine("=============================================================");
                    }
                }
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Error running SQL via JCL: {ex.Message}");
                Console.ResetColor();
            }

            Console.WriteLine("\nPress any key to return to menu...");
            Console.ReadKey();
        }

        static string FormatSqlForJcl(string sql)
        {
            var lines = new List<string>();
            int maxLen = 72;
            for (int i = 0; i < sql.Length; i += maxLen)
            {
                int len = Math.Min(maxLen, sql.Length - i);
                lines.Add(sql.Substring(i, len));
            }
            return string.Join("\n", lines);
        }
    }
}
