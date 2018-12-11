using Micromed.EventCalculation.Common;
using Micromed.ExternalCalculation.Common.Dto;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Micromed.ExternalCalculation.MockExternalCalculation
{
    public class MockPlugin : IExternalCalculationPlugin
    {
        public Guid Guid { get; private set; }
        public string Name { get; private set; }
        public string Description { get; private set; }
        public string Author { get; private set; }
        public string Version { get; private set; }

        private bool isRunning = false;

        private void runCommand(string exeCommand)
        {
            ProcessStartInfo cmdsi = new ProcessStartInfo(exeCommand);

            cmdsi.Arguments = "";

            Process cmd = Process.Start(cmdsi);
            cmd.WaitForExit();
        }

        public MockPlugin()
        {
            Guid = Guid.Parse("1BC8E16D-3C09-40BE-8EC2-F9D7E4F0111C");
            Name = "Mock Calculation";
            Description = "Mock External Calculation plugin";
            Author = "Micromed";
            System.Reflection.Assembly assembly = System.Reflection.Assembly.GetExecutingAssembly();
            FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(assembly.Location);
            Version = fvi.FileVersion;
        }


        public int Start(PluginParametersDto pluginParameters)
        {
            if (isRunning)
                return 1; //isrunning

            runCommand("notepad.exe");

            isRunning = true;
            OnProgress(100);
            return 0;
        }

        public bool Stop()
        {
            if (!isRunning)
                return false;

            isRunning = false;

            OnCancelled();
            return true;
        }


        public event EventHandler Completed;
        protected void OnCompleted()
        {
            EventHandler handler = Completed;
            if (handler != null) handler(this, null);
        }

        public event EventHandler Cancelled;
        protected void OnCancelled()
        {
            EventHandler handler = Cancelled;
            if (handler != null) handler(this, null);
        }

        public event EventHandler<string> Error;
        protected void OnError(string e)
        {
            EventHandler<string> handler = Error;
            if (handler != null) handler(this, e);
        }

        public event EventHandler<int> Progress;
        protected void OnProgress(int e)
        {
            EventHandler<int> handler = Progress;
            if (handler != null) handler(this, e);
        }


        public bool NeedTraceFilePathList
        {
            get { return true; }
        }

        public bool NeedExchangeTraceFilePathList
        {
            get { return false; }
        }

        public bool NeedExchangeEventFilePath
        {
            get { return false; }
        }

        public bool NeedExchangeReportFilePath
        {
            get { return true; }
        }

        public bool NeedExchangeTrendFilePathList
        {
            get { return false; }
        }

        public bool NeedFilteredData
        {
            get { return true; }
        }

        public bool DerivationOptionEnabled
        {
            get { return false; }
        }

        public bool TraceSelectionOptionEnabled
        {
            get { return false; }
        }
    }
}
