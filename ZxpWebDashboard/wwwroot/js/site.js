// ZXP Portal Frontend Logic - site.js

$(document).ready(function () {
    // Session memory for submitted jobs
    let sessionJobs = JSON.parse(sessionStorage.getItem('zxp_jobs')) || [];

    // Initialize Connection Info
    fetchConnectionInfo();

    // Tab Switching Logic
    $('.nav-btn').on('click', function () {
        const tabId = $(this).data('tab');
        
        // Update nav buttons
        $('.nav-btn').removeClass('active');
        $(this).addClass('active');

        // Update active tab panel
        $('.tab-panel').removeClass('active');
        $(`#tab-${tabId}`).addClass('active');

        // Update page title
        const pageTitle = $(this).text().trim();
        $('#page-title').text(pageTitle);

        // Special handling
        if (tabId === 'job-queue') {
            renderJobsQueue();
        }
    });

    // Subtab switching in SQL Console
    $('.btn-tab-sub').on('click', function () {
        const subtabId = $(this).data('subtab');
        $('.btn-tab-sub').removeClass('active');
        $(this).addClass('active');

        $('.subtab-panel').removeClass('active');
        $(`#${subtabId}`).addClass('active');
    });

    // Modal Tab switching
    $('.btn-modal-tab').on('click', function () {
        const spoolTab = $(this).data('spooltab');
        $('.btn-modal-tab').removeClass('active');
        $(this).addClass('active');

        $('.modal-spool-panel').removeClass('active');
        $(`#${spoolTab}`).addClass('active');
    });

    /* ================================================================= */
    /* 1. DATASET EXPLORER LOGIC                                         */
    /* ================================================================= */
    let currentOpenDataset = '';
    let currentOpenMember = '';

    $('#btn-search-datasets').on('click', function () {
        const dsLevel = $('#ds-level-input').val().trim();
        if (!dsLevel) return;

        showLoader("Searching datasets on mainframe...");
        $.ajax({
            url: `/api/mainframe/datasets?dsLevel=${encodeURIComponent(dsLevel)}`,
            method: 'GET',
            success: function (datasets) {
                hideLoader();
                $('#datasets-empty-state').addClass('d-none');
                $('#datasets-list').removeClass('d-none');
                
                const list = $('#datasets-list');
                list.empty();

                if (datasets.length === 0) {
                    list.append('<div class="p-3 text-center text-muted">No datasets found.</div>');
                    return;
                }

                datasets.forEach(ds => {
                    const isPds = ds.endsWith('.JCL') || ds.endsWith('.COBOL') || ds.endsWith('.LOAD') || ds.endsWith('.CNTL') || ds.endsWith('.CBL') || ds.endsWith('.SRC');
                    const icon = isPds ? '<i class="fa-solid fa-folder text-warning"></i>' : '<i class="fa-solid fa-file-lines text-info"></i>';
                    
                    list.append(`
                        <button class="list-item-custom dataset-item" data-name="${ds}" data-pds="${isPds}">
                            <span>${icon} ${ds}</span>
                            <span class="item-meta">${isPds ? 'PDS' : 'SEQ'}</span>
                        </button>
                    `);
                });
            },
            error: function (xhr) {
                hideLoader();
                alert("Error searching datasets: " + xhr.responseText);
            }
        });
    });

    // Dataset click handler
    $(document).on('click', '.dataset-item', function () {
        $('.dataset-item').removeClass('active');
        $(this).addClass('active');

        const datasetName = $(this).data('name');
        const isPds = $(this).data('pds');

        currentOpenDataset = datasetName;
        currentOpenMember = '';

        if (isPds) {
            $('#members-card').removeClass('d-none');
            $('#selected-ds-label').text(datasetName);
            loadMembers(datasetName);
        } else {
            $('#members-card').addClass('d-none');
            loadContent(datasetName, null);
        }
    });

    function loadMembers(datasetName) {
        $('#members-list').empty().append('<div class="p-3 text-center text-muted"><i class="fa-solid fa-spinner fa-spin"></i> Loading members...</div>');
        
        $.ajax({
            url: `/api/mainframe/members?datasetName=${encodeURIComponent(datasetName)}`,
            method: 'GET',
            success: function (members) {
                const list = $('#members-list');
                list.empty();

                if (members.length === 0) {
                    list.append('<div class="p-3 text-center text-muted">No members found.</div>');
                    return;
                }

                members.forEach(member => {
                    list.append(`
                        <button class="list-item-custom member-item" data-dataset="${datasetName}" data-name="${member}">
                            <span><i class="fa-solid fa-file-code text-neon"></i> ${member}</span>
                        </button>
                    `);
                });
            },
            error: function (xhr) {
                $('#members-list').empty().append(`<div class="p-3 text-center text-danger">Error loading members.</div>`);
            }
        });
    }

    // Member click handler
    $(document).on('click', '.member-item', function () {
        $('.member-item').removeClass('active');
        $(this).addClass('active');

        const datasetName = $(this).data('dataset');
        const memberName = $(this).data('name');
        
        currentOpenDataset = datasetName;
        currentOpenMember = memberName;

        loadContent(datasetName, memberName);
    });

    function loadContent(datasetName, memberName) {
        showLoader(`Retrieving content for ${datasetName}${memberName ? `(${memberName})` : ''}...`);
        
        $.ajax({
            url: `/api/mainframe/content?datasetName=${encodeURIComponent(datasetName)}&memberName=${encodeURIComponent(memberName || '')}`,
            method: 'GET',
            success: function (res) {
                hideLoader();
                const path = memberName ? `${datasetName}(${memberName})` : datasetName;
                $('#editor-file-path').text(path);
                
                const textarea = $('#editor-textarea');
                textarea.val(res.content);
                textarea.removeAttr('readonly');
                
                $('#btn-save-content').removeClass('d-none');
                $('#editor-status').text("Editing file...");
            },
            error: function (xhr) {
                hideLoader();
                alert("Error loading content: " + xhr.responseText);
            }
        });
    }

    // Save Content handler
    $('#btn-save-content').on('click', function () {
        if (!currentOpenDataset) return;
        
        const content = $('#editor-textarea').val();
        const payload = {
            datasetName: currentOpenDataset,
            memberName: currentOpenMember,
            content: content
        };

        showLoader("Saving content back to mainframe...");
        $.ajax({
            url: '/api/mainframe/content',
            method: 'POST',
            contentType: 'application/json',
            data: JSON.stringify(payload),
            success: function () {
                hideLoader();
                $('#editor-status').text("File saved successfully!");
                setTimeout(() => $('#editor-status').text("Editing file..."), 3000);
            },
            error: function (xhr) {
                hideLoader();
                alert("Error saving file: " + xhr.responseText);
            }
        });
    });

    /* ================================================================= */
    /* 2. JCL RUNNER LOGIC                                               */
    /* ================================================================= */
    $('#btn-submit-jcl').on('click', function () {
        const jclContent = $('#jcl-editor-textarea').val().trim();
        if (!jclContent) {
            alert("JCL content cannot be empty.");
            return;
        }

        showLoader("Submitting JCL to mainframe...");
        $.ajax({
            url: '/api/mainframe/submit-job',
            method: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ jcl: jclContent }),
            success: function (job) {
                hideLoader();
                
                // Save to local session queue
                const newJob = {
                    jobid: job.jobid,
                    jobname: job.jobname,
                    status: job.status || 'ACTIVE',
                    retcode: job.retcode || 'N/A'
                };
                
                sessionJobs.unshift(newJob);
                sessionStorage.setItem('zxp_jobs', JSON.stringify(sessionJobs));

                // Switch to jobs tab
                $('[data-tab="job-queue"]').trigger('click');
                
                // Start tracking job status
                trackJobStatus(newJob.jobname, newJob.jobid);
            },
            error: function (xhr) {
                hideLoader();
                alert("Error submitting JCL job: " + xhr.responseText);
            }
        });
    });

    /* ================================================================= */
    /* 3. SQL CONSOLE LOGIC                                              */
    /* ================================================================= */
    $('#btn-execute-sql').on('click', function () {
        const sqlQuery = $('#sql-textarea').val().trim() || $('#sql-textarea').attr('placeholder');
        const progName = $('#sql-utility-select').val();
        const planName = $('#sql-plan-input').val().trim();

        showLoader("Submitting dynamic SQL job to Db2...");
        $.ajax({
            url: '/api/mainframe/run-sql',
            method: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({
                sqlQuery: sqlQuery,
                progName: progName,
                planName: planName
            }),
            success: function (res) {
                hideLoader();
                
                // Add this JCL SQL job to session queue
                const newJob = {
                    jobid: res.jobid,
                    jobname: res.jobname,
                    status: 'OUTPUT',
                    retcode: res.retcode || 'CC 0000'
                };
                sessionJobs.unshift(newJob);
                sessionStorage.setItem('zxp_jobs', JSON.stringify(sessionJobs));

                // Show Results Card
                $('#sql-results-card').removeClass('d-none');
                
                // Load SYSPRINT / SYSTSPRT
                $('#sql-sysprint-text').text(res.sysprint || 'No output.');
                $('#sql-systsprt-text').text(res.systsprt || 'No output.');

                // Populate Grid View
                const thead = $('#sql-grid-thead').empty();
                const tbody = $('#sql-grid-tbody').empty();

                if (res.success && res.columns.length > 0) {
                    // Populate Header
                    let headerHtml = '<tr><th>#</th>';
                    res.columns.forEach(col => {
                        headerHtml += `<th>${col}</th>`;
                    });
                    headerHtml += '</tr>';
                    thead.append(headerHtml);

                    // Populate Rows
                    res.rows.forEach((row, idx) => {
                        let rowHtml = `<tr><td>${idx + 1}</td>`;
                        row.forEach(cell => {
                            rowHtml += `<td>${cell}</td>`;
                        });
                        rowHtml += '</tr>';
                        tbody.append(rowHtml);
                    });

                    // Activate Grid tab
                    $('[data-subtab="subtab-sql-grid"]').trigger('click');
                } else {
                    // It was either non-SELECT or failed
                    thead.append('<tr><th>Execution Status</th></tr>');
                    const msg = res.success ? "Statement executed successfully (Non-SELECT statement)." : `Error: ${res.errorMessage}`;
                    tbody.append(`<tr><td class="${res.success ? 'text-success' : 'text-danger'} font-monospace">${msg}</td></tr>`);
                    
                    // Activate SYSPRINT tab to review
                    $('[data-subtab="subtab-sql-sysprint"]').trigger('click');
                }
            },
            error: function (xhr) {
                hideLoader();
                alert("Error executing SQL: " + xhr.responseText);
            }
        });
    });

    /* ================================================================= */
    /* 4. JOBS QUEUE TRACKING & RENDERING                                */
    /* ================================================================= */
    $('#btn-refresh-jobs').on('click', function () {
        renderJobsQueue();
    });

    function renderJobsQueue() {
        const tbody = $('#jobs-table-body');
        tbody.empty();

        if (sessionJobs.length === 0) {
            tbody.append('<tr><td colspan="5" class="text-center text-muted py-4">No jobs submitted in this session.</td></tr>');
            return;
        }

        sessionJobs.forEach(job => {
            let statusClass = 'active';
            if (job.status === 'OUTPUT') {
                statusClass = job.retcode.includes('CC 0000') || job.retcode === 'CC 0004' ? 'completed' : 'failed';
            }

            tbody.append(`
                <tr>
                    <td class="font-monospace text-neon">${job.jobid}</td>
                    <td class="font-monospace">${job.jobname}</td>
                    <td><span class="job-badge ${statusClass}">${job.status}</span></td>
                    <td class="font-monospace">${job.retcode}</td>
                    <td class="text-end">
                        <button class="btn btn-outline-info btn-sm btn-view-spool" data-id="${job.jobid}" data-name="${job.jobname}">
                            <i class="fa-solid fa-file-lines"></i> View Spool Output
                        </button>
                    </td>
                </tr>
            `);
        });
    }

    // View Job Spool details in modal
    $(document).on('click', '.btn-view-spool', function () {
        const jobId = $(this).data('id');
        const jobName = $(this).data('name');

        $('#spoolModalTitle').text(`Job Output Spool - ${jobName} (${jobId})`);
        $('#modal-sysprint-text').text("Loading SYSPRINT spool...");
        $('#modal-systsprt-text').text("Loading SYSTSPRT spool...");
        
        const myModal = new bootstrap.Modal(document.getElementById('spoolModal'));
        myModal.show();

        // Switch to SYSPrint tab by default
        $('[data-spooltab="modal-sysprint"]').trigger('click');

        $.ajax({
            url: `/api/mainframe/job-output?jobName=${encodeURIComponent(jobName)}&jobId=${encodeURIComponent(jobId)}`,
            method: 'GET',
            success: function (res) {
                $('#modal-sysprint-text').text(res.sysprint || 'No output recorded in SYSPRINT.');
                $('#modal-systsprt-text').text(res.systsprt || 'No output recorded in SYSTSPRT.');
            },
            error: function (xhr) {
                $('#modal-sysprint-text').text("Error fetching job spool output: " + xhr.responseText);
                $('#modal-systsprt-text').text("Error fetching job spool output.");
            }
        });
    });

    // Tracking active job status via polling
    function trackJobStatus(jobName, jobId) {
        const timer = setInterval(() => {
            $.ajax({
                url: `/api/mainframe/job-status?jobName=${encodeURIComponent(jobName)}&jobId=${encodeURIComponent(jobId)}`,
                method: 'GET',
                success: function (job) {
                    if (job.status === 'OUTPUT') {
                        clearInterval(timer);
                        
                        // Update session array
                        sessionJobs = sessionJobs.map(j => {
                            if (j.jobid === jobId) {
                                return {
                                    jobid: job.jobid,
                                    jobname: job.jobname,
                                    status: job.status,
                                    retcode: job.retcode || 'CC 0000'
                                };
                            }
                            return j;
                        });
                        sessionStorage.setItem('zxp_jobs', JSON.stringify(sessionJobs));

                        // Refresh UI
                        if ($('#tab-job-queue').hasClass('active')) {
                            renderJobsQueue();
                        }
                    }
                },
                error: function () {
                    clearInterval(timer);
                }
            });
        }, 3000);
    }

    /* ================================================================= */
    /* 5. CONNECTION CONFIGS & LOADER LOGICS                            */
    /* ================================================================= */
    function fetchConnectionInfo() {
        $.ajax({
            url: '/api/mainframe/connection',
            method: 'GET',
            success: function (res) {
                $('#header-connection-url').text(res.url);
                $('#sidebar-username').text(res.username);
                $('#settings-url').val(res.url);
                $('#settings-username').val(res.username);
            }
        });
    }

    $('#btn-save-settings').on('click', function () {
        alert("Settings applied successfully for the local browser session context! (Server configurations remain bound to RACF AppSettings configurations).");
    });

    function showLoader(message) {
        $('#loader-message').text(message);
        $('#global-loader').removeClass('d-none');
    }

    function hideLoader() {
        $('#global-loader').addClass('d-none');
    }
});
