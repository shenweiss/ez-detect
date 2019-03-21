namespace HFO_ENGINE
{
    partial class Progress
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
            this.components = new System.ComponentModel.Container();
            this.Progress_title = new System.Windows.Forms.Label();
            this.ProgressBar = new System.Windows.Forms.ProgressBar();
            this.Progress_warning = new System.Windows.Forms.Label();
            this.timer = new System.Windows.Forms.Timer(this.components);
            this.label6 = new System.Windows.Forms.Label();
            this.hours_label = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.minutes_label = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.seconds_label = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.label8 = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.previous_hs_txt = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.previous_min_label = new System.Windows.Forms.Label();
            this.previous_min_txt = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.previous_snds_txt = new System.Windows.Forms.TextBox();
            this.SuspendLayout();
            // 
            // Progress_title
            // 
            this.Progress_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Progress_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Progress_title.Location = new System.Drawing.Point(45, 55);
            this.Progress_title.Name = "Progress_title";
            this.Progress_title.Size = new System.Drawing.Size(177, 40);
            this.Progress_title.TabIndex = 30;
            this.Progress_title.Text = "Progress";
            // 
            // ProgressBar
            // 
            this.ProgressBar.BackColor = System.Drawing.Color.Silver;
            this.ProgressBar.Location = new System.Drawing.Point(50, 176);
            this.ProgressBar.Name = "ProgressBar";
            this.ProgressBar.Size = new System.Drawing.Size(380, 15);
            this.ProgressBar.Style = System.Windows.Forms.ProgressBarStyle.Continuous;
            this.ProgressBar.TabIndex = 31;
            // 
            // Progress_warning
            // 
            this.Progress_warning.BackColor = System.Drawing.Color.Transparent;
            this.Progress_warning.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Progress_warning.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Progress_warning.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Progress_warning.Location = new System.Drawing.Point(47, 120);
            this.Progress_warning.Name = "Progress_warning";
            this.Progress_warning.Size = new System.Drawing.Size(334, 30);
            this.Progress_warning.TabIndex = 32;
            this.Progress_warning.Text = "Please wait until the progress bar gets to the end...";
            // 
            // timer
            // 
            this.timer.Interval = 1000;
            this.timer.Tick += new System.EventHandler(this.timer_Tick);
            // 
            // label6
            // 
            this.label6.BackColor = System.Drawing.Color.White;
            this.label6.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label6.Location = new System.Drawing.Point(256, 287);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(150, 2);
            this.label6.TabIndex = 34;
            // 
            // hours_label
            // 
            this.hours_label.Font = new System.Drawing.Font("Arial", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.hours_label.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.hours_label.Location = new System.Drawing.Point(258, 247);
            this.hours_label.Margin = new System.Windows.Forms.Padding(0);
            this.hours_label.Name = "hours_label";
            this.hours_label.Size = new System.Drawing.Size(50, 40);
            this.hours_label.TabIndex = 37;
            this.hours_label.Text = "00";
            this.hours_label.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label4
            // 
            this.label4.Font = new System.Drawing.Font("Arial", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label4.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label4.Location = new System.Drawing.Point(358, 247);
            this.label4.Margin = new System.Windows.Forms.Padding(0);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(17, 40);
            this.label4.TabIndex = 40;
            this.label4.Text = ":";
            this.label4.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // minutes_label
            // 
            this.minutes_label.Font = new System.Drawing.Font("Arial", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.minutes_label.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.minutes_label.Location = new System.Drawing.Point(308, 247);
            this.minutes_label.Margin = new System.Windows.Forms.Padding(0);
            this.minutes_label.Name = "minutes_label";
            this.minutes_label.Size = new System.Drawing.Size(50, 40);
            this.minutes_label.TabIndex = 41;
            this.minutes_label.Text = "00";
            this.minutes_label.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label2
            // 
            this.label2.Font = new System.Drawing.Font("Arial", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label2.Location = new System.Drawing.Point(349, 247);
            this.label2.Margin = new System.Windows.Forms.Padding(0);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(17, 40);
            this.label2.TabIndex = 42;
            this.label2.Text = ":";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // seconds_label
            // 
            this.seconds_label.Font = new System.Drawing.Font("Arial", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.seconds_label.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.seconds_label.Location = new System.Drawing.Point(358, 247);
            this.seconds_label.Margin = new System.Windows.Forms.Padding(0);
            this.seconds_label.Name = "seconds_label";
            this.seconds_label.Size = new System.Drawing.Size(50, 40);
            this.seconds_label.TabIndex = 43;
            this.seconds_label.Text = "00";
            this.seconds_label.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label5
            // 
            this.label5.Font = new System.Drawing.Font("Arial", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label5.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label5.Location = new System.Drawing.Point(299, 247);
            this.label5.Margin = new System.Windows.Forms.Padding(0);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(17, 40);
            this.label5.TabIndex = 44;
            this.label5.Text = ":";
            this.label5.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label8
            // 
            this.label8.BackColor = System.Drawing.Color.Transparent;
            this.label8.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label8.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.75F);
            this.label8.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label8.Location = new System.Drawing.Point(83, 217);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(266, 30);
            this.label8.TabIndex = 45;
            this.label8.Text = "Running time of current execution:";
            // 
            // label1
            // 
            this.label1.BackColor = System.Drawing.Color.Transparent;
            this.label1.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 10.75F);
            this.label1.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label1.Location = new System.Drawing.Point(47, 332);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(196, 30);
            this.label1.TabIndex = 46;
            this.label1.Text = "Time of previous execution:";
            // 
            // previous_hs_txt
            // 
            this.previous_hs_txt.BackColor = System.Drawing.SystemColors.Info;
            this.previous_hs_txt.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.previous_hs_txt.Font = new System.Drawing.Font("Microsoft Sans Serif", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.previous_hs_txt.ForeColor = System.Drawing.SystemColors.ControlText;
            this.previous_hs_txt.Location = new System.Drawing.Point(355, 332);
            this.previous_hs_txt.Name = "previous_hs_txt";
            this.previous_hs_txt.Size = new System.Drawing.Size(75, 20);
            this.previous_hs_txt.TabIndex = 47;
            this.previous_hs_txt.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // label3
            // 
            this.label3.BackColor = System.Drawing.Color.Transparent;
            this.label3.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label3.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label3.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label3.Location = new System.Drawing.Point(279, 330);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(70, 22);
            this.label3.TabIndex = 48;
            this.label3.Text = "Hours:";
            this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // previous_min_label
            // 
            this.previous_min_label.BackColor = System.Drawing.Color.Transparent;
            this.previous_min_label.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.previous_min_label.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.previous_min_label.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.previous_min_label.Location = new System.Drawing.Point(279, 356);
            this.previous_min_label.Name = "previous_min_label";
            this.previous_min_label.Size = new System.Drawing.Size(70, 22);
            this.previous_min_label.TabIndex = 50;
            this.previous_min_label.Text = "Minutes:";
            this.previous_min_label.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // previous_min_txt
            // 
            this.previous_min_txt.BackColor = System.Drawing.SystemColors.Info;
            this.previous_min_txt.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.previous_min_txt.Font = new System.Drawing.Font("Microsoft Sans Serif", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.previous_min_txt.ForeColor = System.Drawing.SystemColors.ControlText;
            this.previous_min_txt.Location = new System.Drawing.Point(355, 358);
            this.previous_min_txt.Name = "previous_min_txt";
            this.previous_min_txt.Size = new System.Drawing.Size(75, 20);
            this.previous_min_txt.TabIndex = 49;
            this.previous_min_txt.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // label9
            // 
            this.label9.BackColor = System.Drawing.Color.Transparent;
            this.label9.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label9.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label9.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label9.Location = new System.Drawing.Point(279, 382);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(70, 22);
            this.label9.TabIndex = 52;
            this.label9.Text = "Seconds:";
            this.label9.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // previous_snds_txt
            // 
            this.previous_snds_txt.BackColor = System.Drawing.SystemColors.Info;
            this.previous_snds_txt.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.previous_snds_txt.Font = new System.Drawing.Font("Microsoft Sans Serif", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.previous_snds_txt.ForeColor = System.Drawing.SystemColors.ControlText;
            this.previous_snds_txt.Location = new System.Drawing.Point(355, 384);
            this.previous_snds_txt.Name = "previous_snds_txt";
            this.previous_snds_txt.Size = new System.Drawing.Size(75, 20);
            this.previous_snds_txt.TabIndex = 51;
            this.previous_snds_txt.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // Progress
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.label9);
            this.Controls.Add(this.previous_snds_txt);
            this.Controls.Add(this.previous_min_label);
            this.Controls.Add(this.previous_min_txt);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.previous_hs_txt);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.label8);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.seconds_label);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.minutes_label);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.hours_label);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.Progress_warning);
            this.Controls.Add(this.ProgressBar);
            this.Controls.Add(this.Progress_title);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "Progress";
            this.Text = "Progress";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label Progress_title;
        private System.Windows.Forms.ProgressBar ProgressBar;
        private System.Windows.Forms.Label Progress_warning;
        private System.Windows.Forms.Timer timer;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Label hours_label;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label minutes_label;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label seconds_label;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox previous_hs_txt;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label previous_min_label;
        private System.Windows.Forms.TextBox previous_min_txt;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.TextBox previous_snds_txt;
    }
}