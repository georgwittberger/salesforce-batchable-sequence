/**
 * Abstract base class for job sequences.
 */
global inherited sharing virtual class sbs_JobSequence {
    private JobConfig currentJobConfiguration;
    private String currentJobConfigurationSerialized;
    private String successorJobConfigurationsSerialized;

    /**
     * Execute given list of jobs.
     * 
     * @param  jobConfigurations List of job configurations.
     * @return                   Id of the first job.
     */
    global static Id execute(List<JobConfig> jobConfigurations) {
        return executeJobSequence(jobConfigurations);
    }

    /**
     * Create new job sequence without job configurations.
     * 
     * @return   New job sequence.
     */
    protected sbs_JobSequence() {
        this(null);
    }

    /**
     * Create new job sequence with given job configurations.
     * 
     * @param  jobConfigurations List of job configurations.
     * @return                   New job sequence.
     */
    protected sbs_JobSequence(List<JobConfig> jobConfigurations) {
        if (jobConfigurations == null || jobConfigurations.isEmpty()) {
            return;
        }
        List<JobConfig> successorJobConfigurations = new List<JobConfig>(jobConfigurations);
        this.currentJobConfiguration = successorJobConfigurations.remove(0);
        this.currentJobConfigurationSerialized = JSON.serialize(this.currentJobConfiguration);
        this.successorJobConfigurationsSerialized = JSON.serialize(successorJobConfigurations);
    }

    /**
     * Get configuration of the current job.
     * 
     * @return   Configuration of the current job.
     */
    protected JobConfig getCurrentJobConfiguration() {
        if (this.currentJobConfiguration != null) {
            return this.currentJobConfiguration;
        }
        if (String.isBlank(this.currentJobConfigurationSerialized)) {
            return null;
        }
        this.currentJobConfiguration = (JobConfig) JSON.deserialize(this.currentJobConfigurationSerialized, JobConfig.class);
        return this.currentJobConfiguration;
    }

    /**
     * Execute next job in sequence if any.
     * 
     * @return   Id of the next job.
     */
    protected Id executeNextSuccessor() {
        if (String.isBlank(this.successorJobConfigurationsSerialized)) {
            return null;
        }
        List<JobConfig> successorJobConfigurations = (List<JobConfig>) JSON.deserialize(this.successorJobConfigurationsSerialized, List<JobConfig>.class);
        return executeJobSequence(successorJobConfigurations);
    }

    private static Id executeJobSequence(List<JobConfig> jobConfigurations) {
        if (jobConfigurations == null || jobConfigurations.isEmpty()) {
            return null;
        }
        JobConfig nextJobConfiguration = jobConfigurations.get(0);
        switch on nextJobConfiguration.startType {
            when QUEUEABLE_DIRECT {
                sbs_JobSequence nextJob = createNextJobSequence(jobConfigurations);
                return System.enqueueJob((Queueable) nextJob);
            }
            when BATCH_ITERABLE {
                return Database.executeBatch(new sbs_BatchableSequenceIterable(jobConfigurations), nextJobConfiguration.batchSize);
            }
            when BATCH_QUERYLOCATOR {
                return Database.executeBatch(new sbs_BatchableSequenceLocator(jobConfigurations), nextJobConfiguration.batchSize);
            }
            when else {
                sbs_JobSequence nextJob = createNextJobSequence(jobConfigurations);
                return Database.executeBatch((Database.Batchable<SObject>) nextJob, nextJob.currentJobConfiguration.batchSize);
            }
        }
    }

    private static sbs_JobSequence createNextJobSequence(List<JobConfig> jobConfigurations) {
        List<JobConfig> successorJobConfigurations = new List<JobConfig>(jobConfigurations);
        JobConfig nextJobConfiguration = successorJobConfigurations.remove(0);
        sbs_JobSequence nextJob = (sbs_JobSequence) Type.forName(nextJobConfiguration.className).newInstance();
        nextJob.setCurrentJobConfiguration(nextJobConfiguration);
        nextJob.setSuccessorJobConfigurations(successorJobConfigurations);
        return nextJob;
    }

    private void setCurrentJobConfiguration(JobConfig currentJobConfiguration) {
        this.currentJobConfiguration = currentJobConfiguration;
        this.currentJobConfigurationSerialized = currentJobConfiguration != null ? JSON.serialize(currentJobConfiguration) : null;
    }

    private void setSuccessorJobConfigurations(List<JobConfig> successorJobConfigurations) {
        this.successorJobConfigurationsSerialized = successorJobConfigurations != null ? JSON.serialize(successorJobConfigurations) : null;
    }

    /**
     * Configuration of a single job.
     */
    global class JobConfig {
        /**
         * Qualified name of the Apex class to execute.
         */
        global String className;
        /**
         * Start type of the job.
         */
        global StartType startType;
        /**
         * Number of records to process per batch (for Database.Batchable classes).
         */
        global Integer batchSize;
        /**
         * Additional data to pass into the job.
         */
        global Map<String, Object> data;

        global JobConfig() {}

        /**
         * Create new job configuration with default start type and default batch size.
         * 
         * @param  className Qualified name of the Apex class to execute.
         * @return           New job configuration.
         */
        global JobConfig(String className) {
            this(className, sbs_JobSequence.StartType.BATCH_DIRECT);
        }

        /**
         * Create new job configuration with given data, default start type and default batch size.
         * 
         * @param  className Qualified name of the Apex class to execute.
         * @param  data      Additional data to pass into the job.
         * @return           New job configuration.
         */
        global JobConfig(String className, Map<String, Object> data) {
            this(className, 200, data);
        }

        /**
         * Create new job configuration with given start type and default batch size.
         * 
         * @param  className Qualified name of the Apex class to execute.
         * @param  startType Start type of the job.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType) {
            this(className, startType, 200);
        }

        /**
         * Create new job configuration with given batch size and default start type.
         * 
         * @param  className Qualified name of the Apex class to execute.
         * @param  batchSize Number of records to process per batch.
         * @return           New job configuration.
         */
        global JobConfig(String className, Integer batchSize) {
            this(className, sbs_JobSequence.StartType.BATCH_DIRECT, batchSize);
        }

        /**
         * Create new job configuration with given start type and batch size.
         * 
         * @param  className Qualified name of the Apex class to execute.
         * @param  startType Start type of the job.
         * @param  batchSize Number of records to process per batch.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType, Integer batchSize) {
            this(className, startType, batchSize, null);
        }

        /**
         * Create new job configuration with given batch size, data and default start type.
         * 
         * @param  className Qualified name of the Apex class to execute.
         * @param  batchSize Number of records to process per batch.
         * @param  data      Additional data to pass into the job.
         * @return           New job configuration.
         */
        global JobConfig(String className, Integer batchSize, Map<String, Object> data) {
            this(className, sbs_JobSequence.StartType.BATCH_DIRECT, batchSize, data);
        }

        /**
         * Create new job configuration with given parameters.
         * 
         * @param  className Qualified name of the Apex class to execute.
         * @param  startType Start type of the job.
         * @param  batchSize Number of records to process per batch.
         * @param  data      Additional data to pass into the job.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType, Integer batchSize, Map<String, Object> data) {
            this.className = className;
            this.startType = startType != null ? startType : sbs_JobSequence.StartType.BATCH_DIRECT;
            this.batchSize = batchSize != null && batchSize > 0 ? batchSize : 200;
            this.data = data;
        }
    }

    /**
     * Start type for jobs.
     */
    global enum StartType {
        /**
         * Execute Apex class directly as Queueable. The class must extend sbs_JobSequence and implement Queueable.
         */
        QUEUEABLE_DIRECT,
        /**
         * Execute Apex class directly as Database.Batchable. The class must extend sbs_JobSequence and implement Database.Batchable.
         */
        BATCH_DIRECT,
        /**
         * Execute Apex class using sbs_BatchableSequenceIterable wrapper. The class must implement Database.Batchable
         * and return an Iterable from the start method.
         */
        BATCH_ITERABLE,
        /**
         * Execute Apex class using sbs_BatchableSequenceLocator wrapper. The class must implement Database.Batchable
         * and return a QueryLocator from the start method.
         */
        BATCH_QUERYLOCATOR
    }
}
