/**
 * Abstract base class for batchable sequences.
 */
global inherited sharing virtual class sbs_BatchableSequence {
    private JobConfig currentJobConfig;
    private final String currentJobConfigSerialized;
    private final String successorJobsConfigSerialized;

    protected sbs_BatchableSequence(JobConfig currentJobConfig, List<JobConfig> successorJobsConfig) {
        if (currentJobConfig == null) {
            throw new IllegalArgumentException('Current job configuration must not be null');
        }
        this.currentJobConfig = currentJobConfig;
        this.currentJobConfigSerialized = JSON.serialize(currentJobConfig);
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
            throw new IllegalArgumentException('Current job configuration must not be null');
        }
        return (Database.Batchable<SObject>) Type.forName(currentJobConfig.className).newInstance();
    }

    /**
     * Execute next job in batchable sequence if any.
     */
    protected void executeNextSuccessor() {
        if (String.isBlank(this.successorJobsConfigSerialized)) {
            return;
        }
        List<JobConfig> successorJobsConfig = (List<JobConfig>) JSON.deserialize(this.successorJobsConfigSerialized, List<JobConfig>.class);
        if (successorJobsConfig == null || successorJobsConfig.isEmpty()) {
            return;
        }
        JobConfig nextJobConfig = successorJobsConfig.remove(0);
        if (nextJobConfig.startType == StartType.ITERABLE) {
            Database.executeBatch(new sbs_BatchableSequenceIterable(nextJobConfig, successorJobsConfig), nextJobConfig.batchSize);
        } else if (nextJobConfig.startType == StartType.QUERYLOCATOR) {
            Database.executeBatch(new sbs_BatchableSequenceLocator(nextJobConfig, successorJobsConfig), nextJobConfig.batchSize);
        }
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
         * Return type of the start method in the Database.Batchable class.
         */
        global StartType startType;
        /**
         * Number of records to process per batch.
         */
        global Integer batchSize;

        global JobConfig() {}

        /**
         * Create new job configuration with default batch size.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  startType Return type of the start method in the Database.Batchable class.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType) {
            this(className, startType, 200);
        }

        /**
         * Create new job configuration with given batch size.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  startType Return type of the start method in the Database.Batchable class.
         * @param  batchSize Number of records to process per batch.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType, Integer batchSize) {
            this.className = className;
            this.startType = startType;
            this.batchSize = batchSize;
        }
    }

    /**
     * Possible return types of the start method.
     */
    global enum StartType {
        ITERABLE, QUERYLOCATOR
    }
}
