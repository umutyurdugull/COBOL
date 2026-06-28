using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using NetFrame.Models;
using NetFrame.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ZxpWebDashboard.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MainframeController : ControllerBase
    {
        private readonly IDatasetService _datasetService;
        private readonly IJobService _jobService;
        private readonly ZosmfConfig _config;

        public MainframeController(
            IDatasetService datasetService,
            IJobService jobService,
            IOptions<ZosmfConfig> config)
        {
            _datasetService = datasetService ?? throw new ArgumentNullException(nameof(datasetService));
            _jobService = jobService ?? throw new ArgumentNullException(nameof(jobService));
            _config = config?.Value ?? throw new ArgumentNullException(nameof(config));
        }

        [HttpGet("connection")]
        public IActionResult GetConnectionDetails()
        {
            return Ok(new
            {
                url = _config.BaseUrl,
                username = _config.Username
            });
        }

        [HttpGet("datasets")]
        public async Task<IActionResult> ListDatasets([FromQuery] string dsLevel)
        {
            if (string.IsNullOrWhiteSpace(dsLevel))
                return BadRequest("dsLevel is required.");

            try
            {
                var datasets = await _datasetService.ListDatasetsAsync(dsLevel);
                return Ok(datasets);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("members")]
        public async Task<IActionResult> ListMembers([FromQuery] string datasetName)
        {
            if (string.IsNullOrWhiteSpace(datasetName))
                return BadRequest("datasetName is required.");

            try
            {
                var response = await _datasetService.ListDatasetMembersAsync(datasetName);
                var members = response?.Items?.Select(i => i.Member).ToList() ?? new List<string>();
                return Ok(members);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("content")]
        public async Task<IActionResult> GetContent([FromQuery] string datasetName, [FromQuery] string? memberName = null)
        {
            if (string.IsNullOrWhiteSpace(datasetName))
                return BadRequest("datasetName is required.");

            try
            {
                var content = await _datasetService.RetrieveDatasetContentAsync(datasetName, memberName);
                return Ok(new { content = content ?? string.Empty });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("content")]
        public async Task<IActionResult> SaveContent([FromBody] SaveContentRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.DatasetName))
                return BadRequest("Invalid request payload.");

            try
            {
                // Normalize line endings to Unix style to prevent z/OSMF length/Hayalet record issues
                string normalizedContent = request.Content ?? string.Empty;
                normalizedContent = normalizedContent.Replace("\r\n", "\n").Replace("\r", "\n");
                if (!normalizedContent.EndsWith("\n") && !string.IsNullOrEmpty(normalizedContent))
                {
                    normalizedContent += "\n";
                }

                await _datasetService.WriteDatasetContentAsync(request.DatasetName, request.MemberName, normalizedContent);
                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("submit-job")]
        public async Task<IActionResult> SubmitJob([FromBody] SubmitJclRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Jcl))
                return BadRequest("JCL content is required.");

            try
            {
                // Ensure correct line endings for JCL
                string normalizedJcl = request.Jcl.Replace("\r\n", "\n").Replace("\r", "\n");
                
                var options = new JobSubmissionOptions { JclContent = normalizedJcl };
                var jobStatusStr = await _jobService.SubmitJobAndWaitAsync(options);
                var jobNode = JsonNode.Parse(jobStatusStr);

                return Ok(new
                {
                    jobid = jobNode?["jobid"]?.ToString(),
                    jobname = jobNode?["jobname"]?.ToString(),
                    status = jobNode?["status"]?.ToString(),
                    retcode = jobNode?["retcode"]?.ToString(),
                    rawStatus = jobStatusStr
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("job-status")]
        public async Task<IActionResult> GetJobStatus([FromQuery] string jobName, [FromQuery] string jobId)
        {
            if (string.IsNullOrWhiteSpace(jobName) || string.IsNullOrWhiteSpace(jobId))
                return BadRequest("jobName and jobId are required.");

            try
            {
                var statusStr = await _jobService.GetJobStatusAsync(jobName, jobId);
                var jobNode = JsonNode.Parse(statusStr);
                return Ok(new
                {
                    jobid = jobNode?["jobid"]?.ToString(),
                    jobname = jobNode?["jobname"]?.ToString(),
                    status = jobNode?["status"]?.ToString(),
                    retcode = jobNode?["retcode"]?.ToString(),
                    rawStatus = statusStr
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("job-output")]
        public async Task<IActionResult> GetJobOutput([FromQuery] string jobName, [FromQuery] string jobId)
        {
            if (string.IsNullOrWhiteSpace(jobName) || string.IsNullOrWhiteSpace(jobId))
                return BadRequest("jobName and jobId are required.");

            try
            {
                var jobFiles = await _jobService.ListJobFilesAsync(jobName, jobId);
                var sysTsPrtFile = jobFiles.Find(f => f.DdName == "SYSTSPRT");
                var sysPrintFile = jobFiles.Find(f => f.DdName == "SYSPRINT");

                string tsPrtContent = string.Empty;
                string printContent = string.Empty;

                if (sysTsPrtFile != null && sysTsPrtFile.Id.HasValue)
                {
                    tsPrtContent = await _jobService.GetJobFileRecordsAsync(jobName, jobId, sysTsPrtFile.Id.Value.ToString());
                }

                if (sysPrintFile != null && sysPrintFile.Id.HasValue)
                {
                    printContent = await _jobService.GetJobFileRecordsAsync(jobName, jobId, sysPrintFile.Id.Value.ToString());
                }

                return Ok(new
                {
                    systsprt = tsPrtContent,
                    sysprint = printContent
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("run-sql")]
        public async Task<IActionResult> RunSql([FromBody] RunSqlRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.SqlQuery))
                return BadRequest("SQL Query is required.");

            string progName = request.ProgName ?? "DSNTEP2";
            string planName = request.PlanName ?? "DSNTEPD1";
            string username = _config.Username;

            // Formatter to prevent maxlen=80 error on JCL submission
            string formattedSql = FormatSqlForJcl(request.SqlQuery);
            string runParams = (progName == "DSNTEP2" || progName == "DSNTEP4") ? " PARMS('/ALIGN(MID)')" : "";

            // Construct SQL Execution JCL
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
                var options = new JobSubmissionOptions { JclContent = jclContent };
                var jobStatusStr = await _jobService.SubmitJobAndWaitAsync(options);
                var jobNode = JsonNode.Parse(jobStatusStr);

                string? jobName = jobNode?["jobname"]?.ToString();
                string? jobId = jobNode?["jobid"]?.ToString();
                string? retcode = jobNode?["retcode"]?.ToString();

                if (string.IsNullOrEmpty(jobName) || string.IsNullOrEmpty(jobId))
                {
                    return StatusCode(500, "Could not submit DB2 JCL job.");
                }

                // Fetch Outputs
                var jobFiles = await _jobService.ListJobFilesAsync(jobName, jobId);
                var sysTsPrtFile = jobFiles.Find(f => f.DdName == "SYSTSPRT");
                var sysPrintFile = jobFiles.Find(f => f.DdName == "SYSPRINT");

                string tsPrtContent = string.Empty;
                string printContent = string.Empty;

                if (sysTsPrtFile != null && sysTsPrtFile.Id.HasValue)
                {
                    tsPrtContent = await _jobService.GetJobFileRecordsAsync(jobName, jobId, sysTsPrtFile.Id.Value.ToString());
                }

                if (sysPrintFile != null && sysPrintFile.Id.HasValue)
                {
                    printContent = await _jobService.GetJobFileRecordsAsync(jobName, jobId, sysPrintFile.Id.Value.ToString());
                }

                // Parse DB2 Output Table
                var parsedResult = ParseDb2SysprintTable(printContent);

                return Ok(new
                {
                    jobid = jobId,
                    jobname = jobName,
                    retcode = retcode,
                    systsprt = tsPrtContent,
                    sysprint = printContent,
                    columns = parsedResult.Columns,
                    rows = parsedResult.Rows,
                    success = parsedResult.Success,
                    errorMessage = parsedResult.Message
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        private static string FormatSqlForJcl(string sql)
        {
            var lines = new List<string>();
            int maxLen = 72;
            string cleanSql = sql.Trim();
            if (!cleanSql.EndsWith(";"))
            {
                cleanSql += ";";
            }

            for (int i = 0; i < cleanSql.Length; i += maxLen)
            {
                int len = Math.Min(maxLen, cleanSql.Length - i);
                lines.Add(cleanSql.Substring(i, len));
            }
            return string.Join("\n", lines);
        }

        private static ParsedSqlTable ParseDb2SysprintTable(string sysprint)
        {
            var result = new ParsedSqlTable();
            if (string.IsNullOrEmpty(sysprint))
            {
                result.Success = false;
                result.Message = "Empty output received.";
                return result;
            }

            var lines = sysprint.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            
            // Check for SQL errors in the output
            foreach (var line in lines)
            {
                if (line.Contains("SQLCODE = -") || line.Contains("SQLCODE -"))
                {
                    result.Success = false;
                    result.Message = line.Trim();
                    return result;
                }
            }

            var headers = new List<string>();
            var rows = new List<List<string>>();

            // Parse headers and rows
            foreach (var line in lines)
            {
                string cleanLine = line.Trim();

                // Detect headers: contains | and does not have +-- or row numbers
                if (cleanLine.StartsWith("|") && !cleanLine.Contains("+---") && !cleanLine.Contains("---|"))
                {
                    var cols = cleanLine.Split(new[] { '|' }, StringSplitOptions.RemoveEmptyEntries)
                                        .Select(c => c.Trim())
                                        .Where(c => !string.IsNullOrEmpty(c))
                                        .ToList();
                    
                    if (cols.Count > 0 && headers.Count == 0)
                    {
                        headers = cols;
                    }
                }
                // Detect data row: contains _|
                else if (cleanLine.Contains("_|"))
                {
                    int pipeIdx = cleanLine.IndexOf('|');
                    if (pipeIdx != -1)
                    {
                        var dataCells = cleanLine.Substring(pipeIdx + 1)
                                                 .Split(new[] { '|' }, StringSplitOptions.None)
                                                 .Select(c => c.Trim())
                                                 .ToList();
                        
                        // Remove last empty cell if line ended with |
                        if (dataCells.Count > 0 && string.IsNullOrEmpty(dataCells.Last()))
                        {
                            dataCells.RemoveAt(dataCells.Count - 1);
                        }

                        rows.Add(dataCells);
                    }
                }
            }

            if (headers.Count > 0)
            {
                result.Columns = headers;
                result.Rows = rows;
                result.Success = true;
            }
            else
            {
                result.Success = false;
                result.Message = "No query results found, or statement was a non-SELECT statement.";
            }

            return result;
        }
    }

    public class SaveContentRequest
    {
        public string DatasetName { get; set; } = string.Empty;
        public string? MemberName { get; set; }
        public string Content { get; set; } = string.Empty;
    }

    public class SubmitJclRequest
    {
        public string Jcl { get; set; } = string.Empty;
    }

    public class RunSqlRequest
    {
        public string SqlQuery { get; set; } = string.Empty;
        public string? ProgName { get; set; }
        public string? PlanName { get; set; }
    }

    public class ParsedSqlTable
    {
        public List<string> Columns { get; set; } = new List<string>();
        public List<List<string>> Rows { get; set; } = new List<List<string>>();
        public bool Success { get; set; } = false;
        public string Message { get; set; } = string.Empty;
    }
}
