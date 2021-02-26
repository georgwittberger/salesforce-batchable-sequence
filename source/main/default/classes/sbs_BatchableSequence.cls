/**
 * Abstract base class for batchable wrapper sequences.
 */
global inherited sharing virtual class sbs_BatchableSequence extends sbs_JobSequence {
    /**
     * Create new batchable wrapper sequence without job configurations.
     * 
     * @return   New batchable wrapper sequence.
     */
    protected sbs_BatchableSequence() {
        this(null);
    }

    /**
     * Create new batchable wrapper sequence with given job configurations.
     * 
     * @param  jobConfigurations List of job configurations.
     * @return                   New batchable wrapper sequence.
     */
    protected sbs_BatchableSequence(List<JobConfig> jobConfigurations) {
        super(jobConfigurations);
    }

    /**
     * Create new instance of the Database.Batchable class of the current job.
     * 
     * @return   New instance of the Database.Batchable class.
     */
    protected Database.Batchable<SObject> createBatchableInstance() {
        JobConfig currentJobConfiguration = getCurrentJobConfiguration();
        if (currentJobConfiguration == null) {
            throw new IllegalArgumentException('Current job configuration must not be null in order to create new instance');
        }
        return (Database.Batchable<SObject>) Type.forName(currentJobConfiguration.className).newInstance();
    }
}
