/**
 * Abstract base class for batchable sequences.
 */
global inherited sharing virtual class sbs_BatchableSequence {
    private JobConfig currentJobConfig;
    private String currentJobConfigSerialized;
    private String successorJobsConfigSerialized;

    /**
     * Execute given list of batchable jobs.
     * 
     * @param  jobsConfig List of job configurations.
     * @return            Id of the first batchable job.
     */
    global static Id execute(List<JobConfig> jobsConfig) {
        if (jobsConfig == null || jobsConfig.isEmpty()) {
            return null;
        }
        List<JobConfig> successorJobsConfig = new List<JobConfig>(jobsConfig);
        JobConfig firstJobConfig = successorJobsConfig.remove(0);
        return executeBatchableSequence(firstJobConfig, successorJobsConfig);
    }

    /**
     * Create new batchable sequence without job configuration.
     * 
     * @return   New batchable sequence.
     */
    protected sbs_BatchableSequence() {
        this(null, null);
    }

    /**
     * Create new batchable sequence with given job configuration.
     * 
     * @param  currentJobConfig    Current job configuration.
     * @param  successorJobsConfig List of successor configurations.
     * @return                     New batchable sequence.
     */
    protected sbs_BatchableSequence(JobConfig currentJobConfig, List<JobConfig> successorJobsConfig) {
        this.currentJobConfig = currentJobConfig;
        this.currentJobConfigSerialized = currentJobConfig != null ? JSON.serialize(currentJobConfig) : null;
        this.successorJobsConfigSerialized = successorJobsConfig != null ? JSON.serialize(successorJobsConfig) : null;
    }

    /**
     * Get configuration of the current job.
     * 
     * @return   Configuration of the current job.
     */
    protected JobConfig getCurrentJobConfig() {
        if (this.currentJobConfig != null) {
            return this.currentJobConfig;
        }
        if (String.isBlank(this.currentJobConfigSerialized)) {
            return null;
        }
        this.currentJobConfig = (JobConfig) JSON.deserialize(this.currentJobConfigSerialized, JobConfig.class);
        return this.currentJobConfig;
    }

    /**
     * Create new instance of the Database.Batchable class of the current job.
     * 
     * @return   New instance of the Database.Batchable class.
     */
    protected Database.Batchable<SObject> createCurrentJobInstance() {
        JobConfig currentJobConfig = getCurrentJobConfig();
        if (currentJobConfig == null) {
            throw new IllegalArgumentException('Current job configuration must not be null in order to create new instance');
        }
        return (Database.Batchable<SObject>) Type.forName(currentJobConfig.className).newInstance();
    }

    /**
     * Execute next job in batchable sequence if any.
     * 
     * @return   Id of the next batchable job.
     */
    protected Id executeNextSuccessor() {
        if (String.isBlank(this.successorJobsConfigSerialized)) {
            return null;
        }
        List<JobConfig> successorJobsConfig = (List<JobConfig>) JSON.deserialize(this.successorJobsConfigSerialized, List<JobConfig>.class);
        if (successorJobsConfig == null || successorJobsConfig.isEmpty()) {
            return null;
        }
        JobConfig nextJobConfig = successorJobsConfig.remove(0);
        return executeBatchableSequence(nextJobConfig, successorJobsConfig);
    }

    private static Id executeBatchableSequence(JobConfig currentJobConfig, List<JobConfig> successorJobsConfig) {
        switch on currentJobConfig.startType {
            when DELEGATE_ITERABLE {
                return Database.executeBatch(new sbs_BatchableSequenceIterable(currentJobConfig, successorJobsConfig), currentJobConfig.batchSize);
            }
            when DELEGATE_QUERYLOCATOR {
                return Database.executeBatch(new sbs_BatchableSequenceLocator(currentJobConfig, successorJobsConfig), currentJobConfig.batchSize);
            }
            when else {
                sbs_BatchableSequence currentJob = (sbs_BatchableSequence) Type.forName(currentJobConfig.className).newInstance();
                currentJob.setCurrentJobConfig(currentJobConfig);
                currentJob.setSuccessorJobsConfig(successorJobsConfig);
                return Database.executeBatch((Database.Batchable<SObject>) currentJob, currentJobConfig.batchSize);
            }
        }
    }

    private void setCurrentJobConfig(JobConfig currentJobConfig) {
        this.currentJobConfig = currentJobConfig;
        this.currentJobConfigSerialized = currentJobConfig != null ? JSON.serialize(currentJobConfig) : null;
    }

    private void setSuccessorJobsConfig(List<JobConfig> successorJobsConfig) {
        this.successorJobsConfigSerialized = successorJobsConfig != null ? JSON.serialize(successorJobsConfig) : null;
    }

    /**
     * Configuration of a single batchable job.
     */
    global class JobConfig {
        /**
         * Qualified name of the Database.Batchable class to execute.
         */
        global String className;
        /**
         * Start type of the batchable job.
         */
        global StartType startType;
        /**
         * Number of records to process per batch.
         */
        global Integer batchSize;

        global JobConfig() {}

        /**
         * Create new job configuration with default start type and default batch size.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @return           New job configuration.
         */
        global JobConfig(String className) {
            this(className, sbs_BatchableSequence.StartType.DIRECT);
        }

        /**
         * Create new job configuration with given start type and default batch size.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  startType Start type of the batchable job.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType) {
            this(className, startType, 200);
        }

        /**
         * Create new job configuration with given batch size and default start type.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  batchSize Number of records to process per batch.
         * @return           New job configuration.
         */
        global JobConfig(String className, Integer batchSize) {
            this(className, sbs_BatchableSequence.StartType.DIRECT, batchSize);
        }

        /**
         * Create new job configuration with given start type and batch size.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  startType Start type of the batchable job.
         * @param  batchSize Number of records to process per batch.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType, Integer batchSize) {
            this.className = className;
            this.startType = startType != null ? startType : sbs_BatchableSequence.StartType.DIRECT;
            this.batchSize = batchSize != null && batchSize > 0 ? batchSize : 200;
        }
    }

    /**
     * Start type for batchable jobs.
     */
    global enum StartType {
        /**
         * Execute given class directly as Database.Batchable. The class must be a subclass of sbs_BatchableSequence.
         */
        DIRECT,
        /**
         * Execute given class using a wrapper, assuming that the class returns an Iterable from the start method.
         */
        DELEGATE_ITERABLE,
        /**
         * Execute given class using a wrapper, assuming that the class returns a QueryLocator from the start method.
         */
        DELEGATE_QUERYLOCATOR
    }
}
