﻿#pragma checksum "..\..\Windows1.xaml" "{406ea660-64cf-4c82-b6f0-42d48172a799}" "8D72FA442C804324D57264CDA099E0B5"
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.42000
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using EzDetectGUI;
using System;
using System.Diagnostics;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Media.Imaging;
using System.Windows.Media.Media3D;
using System.Windows.Media.TextFormatting;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Windows.Shell;


namespace EzDetectGUI {
    
    
    /// <summary>
    /// Window1
    /// </summary>
    public partial class Window1 : System.Windows.Window, System.Windows.Markup.IComponentConnector {
        
        
        #line 10 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.Grid Advanced_settings;
        
        #line default
        #line hidden
        
        
        #line 34 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.Button back_btn;
        
        #line default
        #line hidden
        
        
        #line 46 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox username_txt;
        
        #line default
        #line hidden
        
        
        #line 49 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox hostname_txt;
        
        #line default
        #line hidden
        
        
        #line 50 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox host_config_text;
        
        #line default
        #line hidden
        
        
        #line 52 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox command_txt;
        
        #line default
        #line hidden
        
        
        #line 55 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox logfile_txt;
        
        #line default
        #line hidden
        
        
        #line 56 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox trc_dir_txt;
        
        #line default
        #line hidden
        
        
        #line 58 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox trc_txt;
        
        #line default
        #line hidden
        
        
        #line 60 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox evt_txt;
        
        #line default
        #line hidden
        
        
        #line 71 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox python_txt;
        
        #line default
        #line hidden
        
        
        #line 73 "..\..\Windows1.xaml"
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        internal System.Windows.Controls.TextBox Scripts_txt;
        
        #line default
        #line hidden
        
        private bool _contentLoaded;
        
        /// <summary>
        /// InitializeComponent
        /// </summary>
        [System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [System.CodeDom.Compiler.GeneratedCodeAttribute("PresentationBuildTasks", "4.0.0.0")]
        public void InitializeComponent() {
            if (_contentLoaded) {
                return;
            }
            _contentLoaded = true;
            System.Uri resourceLocater = new System.Uri("/EzDetectGUI;component/windows1.xaml", System.UriKind.Relative);
            
            #line 1 "..\..\Windows1.xaml"
            System.Windows.Application.LoadComponent(this, resourceLocater);
            
            #line default
            #line hidden
        }
        
        [System.Diagnostics.DebuggerNonUserCodeAttribute()]
        [System.CodeDom.Compiler.GeneratedCodeAttribute("PresentationBuildTasks", "4.0.0.0")]
        [System.ComponentModel.EditorBrowsableAttribute(System.ComponentModel.EditorBrowsableState.Never)]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Design", "CA1033:InterfaceMethodsShouldBeCallableByChildTypes")]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Maintainability", "CA1502:AvoidExcessiveComplexity")]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1800:DoNotCastUnnecessarily")]
        void System.Windows.Markup.IComponentConnector.Connect(int connectionId, object target) {
            switch (connectionId)
            {
            case 1:
            this.Advanced_settings = ((System.Windows.Controls.Grid)(target));
            return;
            case 2:
            this.back_btn = ((System.Windows.Controls.Button)(target));
            
            #line 34 "..\..\Windows1.xaml"
            this.back_btn.Click += new System.Windows.RoutedEventHandler(this.Back_Button_Click);
            
            #line default
            #line hidden
            return;
            case 3:
            this.username_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 46 "..\..\Windows1.xaml"
            this.username_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Username_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 4:
            this.hostname_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 49 "..\..\Windows1.xaml"
            this.hostname_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Hostname_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 5:
            this.host_config_text = ((System.Windows.Controls.TextBox)(target));
            
            #line 50 "..\..\Windows1.xaml"
            this.host_config_text.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Host_conf_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 6:
            this.command_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 52 "..\..\Windows1.xaml"
            this.command_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Command_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 7:
            this.logfile_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 55 "..\..\Windows1.xaml"
            this.logfile_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Logfile_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 8:
            this.trc_dir_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 56 "..\..\Windows1.xaml"
            this.trc_dir_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Trc_temp_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 9:
            this.trc_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 58 "..\..\Windows1.xaml"
            this.trc_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Trc_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 10:
            this.evt_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 60 "..\..\Windows1.xaml"
            this.evt_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Evt_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 11:
            this.python_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 71 "..\..\Windows1.xaml"
            this.python_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Python_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            case 12:
            this.Scripts_txt = ((System.Windows.Controls.TextBox)(target));
            
            #line 73 "..\..\Windows1.xaml"
            this.Scripts_txt.TextChanged += new System.Windows.Controls.TextChangedEventHandler(this.Scipts_TextBox_TextChanged);
            
            #line default
            #line hidden
            return;
            }
            this._contentLoaded = true;
        }
    }
}

