namespace HFO_ENGINE
{
    partial class TimeWindow
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.Times_title = new System.Windows.Forms.Label();
            this.StartTimeLabel = new System.Windows.Forms.Label();
            this.StopTimeLabel = new System.Windows.Forms.Label();
            this.Str_time_txt = new System.Windows.Forms.TextBox();
            this.Stp_time_txt = new System.Windows.Forms.TextBox();
            this.TimeWindow_save_btn = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.panel2.SuspendLayout();
            this.SuspendLayout();
            // 
            // Times_title
            // 
            this.Times_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Times_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Times_title.Location = new System.Drawing.Point(45, 55);
            this.Times_title.Name = "Times_title";
            this.Times_title.Size = new System.Drawing.Size(189, 40);
            this.Times_title.TabIndex = 1;
            this.Times_title.Text = "Time window";
            // 
            // StartTimeLabel
            // 
            this.StartTimeLabel.BackColor = System.Drawing.Color.Transparent;
            this.StartTimeLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.StartTimeLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.StartTimeLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.StartTimeLabel.Location = new System.Drawing.Point(0, 0);
            this.StartTimeLabel.Name = "StartTimeLabel";
            this.StartTimeLabel.Size = new System.Drawing.Size(330, 26);
            this.StartTimeLabel.TabIndex = 3;
            this.StartTimeLabel.Text = "Start time (seconds after recording started)";
            // 
            // StopTimeLabel
            // 
            this.StopTimeLabel.BackColor = System.Drawing.Color.Transparent;
            this.StopTimeLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.StopTimeLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.StopTimeLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.StopTimeLabel.Location = new System.Drawing.Point(0, 100);
            this.StopTimeLabel.Name = "StopTimeLabel";
            this.StopTimeLabel.Size = new System.Drawing.Size(330, 26);
            this.StopTimeLabel.TabIndex = 4;
            this.StopTimeLabel.Text = "Stop time (seconds after recording started)";
            // 
            // Str_time_txt
            // 
            this.Str_time_txt.Location = new System.Drawing.Point(10, 50);
            this.Str_time_txt.Name = "Str_time_txt";
            this.Str_time_txt.Size = new System.Drawing.Size(100, 20);
            this.Str_time_txt.TabIndex = 5;
            // 
            // Stp_time_txt
            // 
            this.Stp_time_txt.Location = new System.Drawing.Point(10, 150);
            this.Stp_time_txt.Name = "Stp_time_txt";
            this.Stp_time_txt.Size = new System.Drawing.Size(100, 20);
            this.Stp_time_txt.TabIndex = 6;
            // 
            // TimeWindow_save_btn
            // 
            this.TimeWindow_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.TimeWindow_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.TimeWindow_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.TimeWindow_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.TimeWindow_save_btn.Location = new System.Drawing.Point(275, 215);
            this.TimeWindow_save_btn.Name = "TimeWindow_save_btn";
            this.TimeWindow_save_btn.Size = new System.Drawing.Size(82, 34);
            this.TimeWindow_save_btn.TabIndex = 8;
            this.TimeWindow_save_btn.Text = "Save";
            this.TimeWindow_save_btn.UseVisualStyleBackColor = true;
            this.TimeWindow_save_btn.Click += new System.EventHandler(this.TimeWindow_save_btn_Click);
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.TimeWindow_save_btn);
            this.panel2.Controls.Add(this.StartTimeLabel);
            this.panel2.Controls.Add(this.Stp_time_txt);
            this.panel2.Controls.Add(this.Str_time_txt);
            this.panel2.Controls.Add(this.StopTimeLabel);
            this.panel2.Location = new System.Drawing.Point(55, 120);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 250);
            this.panel2.TabIndex = 11;
            // 
            // TimeWindow
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.Times_title);
            this.Controls.Add(this.panel2);
            this.ForeColor = System.Drawing.Color.Black;
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "TimeWindow";
            this.Text = "TimeWindow";
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label Times_title;
        private System.Windows.Forms.Label StartTimeLabel;
        private System.Windows.Forms.Label StopTimeLabel;
        private System.Windows.Forms.TextBox Str_time_txt;
        private System.Windows.Forms.TextBox Stp_time_txt;
        private System.Windows.Forms.Button TimeWindow_save_btn;
        private System.Windows.Forms.Panel panel2;
    }
}