@IsTest
class sbs_JobSequenceTest {
    @IsTest
    static void providesCurrentJobConfiguration() {
        Test.startTest();
        sbs_JobSequenceMock jobSequence = new sbs_JobSequenceMock(new List<sbs_JobSequence.JobConfig>{
            new sbs_JobSequence.JobConfig('FirstTestClass', sbs_JobSequence.StartType.BATCH_ITERABLE, 240, 'First Data'),
            new sbs_JobSequence.JobConfig('SecondTestClass', sbs_JobSequence.StartType.BATCH_QUERYLOCATOR, 120, 'Second Data'),
            new sbs_JobSequence.JobConfig('ThirdTestClass', sbs_JobSequence.StartType.BATCH_DIRECT, 60, 'Third Data')
        });
        sbs_JobSequence.JobConfig firstJobConfig = jobSequence.getDelegateCurrentJobConfiguration();
        Test.stopTest();
        System.assertNotEquals(null, firstJobConfig, 'Current job configuration should not be null');
        System.assertEquals('FirstTestClass', firstJobConfig.className, 'Current job configuration should have expected Apex class');
        System.assertEquals(sbs_JobSequence.StartType.BATCH_ITERABLE, firstJobConfig.startType, 'Current job configuration should have expected start type');
        System.assertEquals(240, firstJobConfig.batchSize, 'Current job configuration should have expected batch size');
        System.assertEquals('First Data', firstJobConfig.data, 'Current job configuration should have expected data');
    }

    @IsTest
    static void executesJobSequenceWithDirectBatchable() {
        Test.startTest();
        sbs_JobSequence.execute(new List<sbs_JobSequence.JobConfig>{
            new sbs_JobSequence.JobConfig('sbs_BatchableLocatorMock', sbs_JobSequence.StartType.BATCH_DIRECT, 240, 'Batchable Data'),
            new sbs_JobSequence.JobConfig('sbs_QueueableMock', sbs_JobSequence.StartType.QUEUEABLE_DIRECT, 'Queueable Data')
        });
        Test.stopTest();
        System.assertEquals(1, sbs_BatchableLocatorMock.startInvocations, 'Batchable job should have been started');
        System.assertEquals('sbs_BatchableLocatorMock', sbs_BatchableLocatorMock.startJobConfiguration.className, 'Batchable job should have expected Apex class');
        System.assertEquals(sbs_JobSequence.StartType.BATCH_DIRECT, sbs_BatchableLocatorMock.startJobConfiguration.startType, 'Batchable job should have expected start type');
        System.assertEquals(240, sbs_BatchableLocatorMock.startJobConfiguration.batchSize, 'Batchable job should have expected batch size');
        System.assertEquals('Batchable Data', sbs_BatchableLocatorMock.startJobConfiguration.data, 'Batchable job should have expected data');
        System.assertEquals(1, sbs_BatchableLocatorMock.executeInvocations, 'Batchable job should have been executed');
        System.assertEquals(1, sbs_BatchableLocatorMock.finishInvocations, 'Batchable job should have been finished');
        System.assertEquals(1, sbs_QueueableMock.executeInvocations, 'Queueable job should have been executed');
        System.assertEquals('sbs_QueueableMock', sbs_QueueableMock.executeJobConfiguration.className, 'Queueable job should have expected Apex class');
        System.assertEquals(sbs_JobSequence.StartType.QUEUEABLE_DIRECT, sbs_QueueableMock.executeJobConfiguration.startType, 'Queueable job should have expected start type');
        System.assertEquals('Queueable Data', sbs_QueueableMock.executeJobConfiguration.data, 'Queueable job should have expected data');
        System.assert(sbs_QueueableMock.executeTime >= sbs_BatchableLocatorMock.finishTime, 'Queueable job should have been executed after Batchable job finished');
    }

    @IsTest
    static void executesJobSequenceWithQueryLocatorWrapper() {
        Test.startTest();
        sbs_JobSequence.execute(new List<sbs_JobSequence.JobConfig>{
            new sbs_JobSequence.JobConfig('sbs_BatchableLocatorMock', sbs_JobSequence.StartType.BATCH_QUERYLOCATOR, 240, 'Batchable Data'),
            new sbs_JobSequence.JobConfig('sbs_QueueableMock', sbs_JobSequence.StartType.QUEUEABLE_DIRECT, 'Queueable Data')
        });
        Test.stopTest();
        System.assertEquals(1, sbs_BatchableLocatorMock.startInvocations, 'Batchable job should have been started');
        System.assertEquals(1, sbs_BatchableLocatorMock.executeInvocations, 'Batchable job should have been executed');
        System.assertEquals(1, sbs_BatchableLocatorMock.finishInvocations, 'Batchable job should have been finished');
        System.assertEquals(1, sbs_QueueableMock.executeInvocations, 'Queueable job should have been executed');
        System.assert(sbs_QueueableMock.executeTime >= sbs_BatchableLocatorMock.finishTime, 'Queueable job should have been executed after Batchable job finished');
    }

    @IsTest
    static void executesJobSequenceWithIterableWrapper() {
        Test.startTest();
        sbs_JobSequence.execute(new List<sbs_JobSequence.JobConfig>{
            new sbs_JobSequence.JobConfig('sbs_BatchableIterableMock', sbs_JobSequence.StartType.BATCH_ITERABLE, 240, 'Batchable Data'),
            new sbs_JobSequence.JobConfig('sbs_QueueableMock', sbs_JobSequence.StartType.QUEUEABLE_DIRECT, 'Queueable Data')
        });
        Test.stopTest();
        System.assertEquals(1, sbs_BatchableIterableMock.startInvocations, 'Batchable job should have been started');
        System.assertEquals(1, sbs_BatchableIterableMock.executeInvocations, 'Batchable job should have been executed');
        System.assertEquals(1, sbs_BatchableIterableMock.finishInvocations, 'Batchable job should have been finished');
        System.assertEquals(1, sbs_QueueableMock.executeInvocations, 'Queueable job should have been executed');
        System.assert(sbs_QueueableMock.executeTime >= sbs_BatchableIterableMock.finishTime, 'Queueable job should have been executed after Batchable job finished');
    }
}
