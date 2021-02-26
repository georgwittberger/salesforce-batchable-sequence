/**
 * Abstract base class for batchable sequences.
 */
global inherited sharing virtual class sbs_BatchableSequence {
    private JobConfig currentJobConfiguration;
    private String currentJobConfigurationSerialized;
    private String successorJobConfigurationsSerialized;

    /**
     * Execute given list of batchable jobs.
     * 
     * @param  jobConfigurations List of job configurations.
     * @return                   Id of the first batchable job.
     */
    global static Id execute(List<JobConfig> jobConfigurations) {
        return executeBatchableSequence(jobConfigurations);
    }

    /**
     * Create new batchable sequence without job configuration.
     * 
     * @return   New batchable sequence.
     */
    protected sbs_BatchableSequence() {
        this(null);
    }

    /**
     * Create new batchable sequence with given job configurations.
     * 
     * @param  jobConfigurations List of job configurations.
     * @return                   New batchable sequence.
     */
    protected sbs_BatchableSequence(List<JobConfig> jobConfigurations) {
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
     * Create new instance of the Database.Batchable class of the current job.
     * 
     * @return   New instance of the Database.Batchable class.
     */
    protected Database.Batchable<SObject> createCurrentJobInstance() {
        JobConfig currentJobConfiguration = getCurrentJobConfiguration();
        if (currentJobConfiguration == null) {
            throw new IllegalArgumentException('Current job configuration must not be null in order to create new instance');
        }
        return (Database.Batchable<SObject>) Type.forName(currentJobConfiguration.className).newInstance();
    }

    /**
     * Execute next job in batchable sequence if any.
     * 
     * @return   Id of the next batchable job.
     */
    protected Id executeNextSuccessor() {
        if (String.isBlank(this.successorJobConfigurationsSerialized)) {
            return null;
        }
        List<JobConfig> successorJobConfigurations = (List<JobConfig>) JSON.deserialize(this.successorJobConfigurationsSerialized, List<JobConfig>.class);
        return executeBatchableSequence(successorJobConfigurations);
    }

    private static Id executeBatchableSequence(List<JobConfig> jobConfigurations) {
        if (jobConfigurations == null || jobConfigurations.isEmpty()) {
            return null;
        }
        JobConfig nextJobConfiguration = jobConfigurations.get(0);
        switch on nextJobConfiguration.startType {
            when DELEGATE_ITERABLE {
                return Database.executeBatch(new sbs_BatchableSequenceIterable(jobConfigurations), nextJobConfiguration.batchSize);
            }
            when DELEGATE_QUERYLOCATOR {
                return Database.executeBatch(new sbs_BatchableSequenceLocator(jobConfigurations), nextJobConfiguration.batchSize);
            }
            when else {
                List<JobConfig> successorJobConfigurations = new List<JobConfig>(jobConfigurations);
                JobConfig currentJobConfiguration = successorJobConfigurations.remove(0);
                sbs_BatchableSequence currentJob = (sbs_BatchableSequence) Type.forName(currentJobConfiguration.className).newInstance();
                currentJob.setCurrentJobConfiguration(currentJobConfiguration);
                currentJob.setSuccessorJobConfigurations(successorJobConfigurations);
                return Database.executeBatch((Database.Batchable<SObject>) currentJob, currentJobConfiguration.batchSize);
            }
        }
    }

    private void setCurrentJobConfiguration(JobConfig currentJobConfiguration) {
        this.currentJobConfiguration = currentJobConfiguration;
        this.currentJobConfigurationSerialized = currentJobConfiguration != null ? JSON.serialize(currentJobConfiguration) : null;
    }

    private void setSuccessorJobConfigurations(List<JobConfig> successorJobConfigurations) {
        this.successorJobConfigurationsSerialized = successorJobConfigurations != null ? JSON.serialize(successorJobConfigurations) : null;
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
        /**
         * Additional data to pass into the batchable job.
         */
        global Map<String, Object> data;

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
         * Create new job configuration with given data, default start type and default batch size.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  data      Additional data to pass into the batchable job.
         * @return           New job configuration.
         */
        global JobConfig(String className, Map<String, Object> data) {
            this(className, 200, data);
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
            this(className, startType, batchSize, null);
        }

        /**
         * Create new job configuration with given batch size, data and default start type.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  batchSize Number of records to process per batch.
         * @param  data      Additional data to pass into the batchable job.
         * @return           New job configuration.
         */
        global JobConfig(String className, Integer batchSize, Map<String, Object> data) {
            this(className, sbs_BatchableSequence.StartType.DIRECT, batchSize, data);
        }

        /**
         * Create new job configuration with given parameters.
         * 
         * @param  className Qualified name of the Database.Batchable class to execute.
         * @param  startType Start type of the batchable job.
         * @param  batchSize Number of records to process per batch.
         * @param  data      Additional data to pass into the batchable job.
         * @return           New job configuration.
         */
        global JobConfig(String className, StartType startType, Integer batchSize, Map<String, Object> data) {
            this.className = className;
            this.startType = startType != null ? startType : sbs_BatchableSequence.StartType.DIRECT;
            this.batchSize = batchSize != null && batchSize > 0 ? batchSize : 200;
            this.data = data;
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
