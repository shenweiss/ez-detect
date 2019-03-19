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
            this.Progress_title = new System.Windows.Forms.Label();
            this.ProgressBar = new System.Windows.Forms.ProgressBar();
            this.Progress_warning = new System.Windows.Forms.Label();
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
            // Progress
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.Progress_warning);
            this.Controls.Add(this.ProgressBar);
            this.Controls.Add(this.Progress_title);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "Progress";
            this.Text = "Progress";
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label Progress_title;
        private System.Windows.Forms.ProgressBar ProgressBar;
        private System.Windows.Forms.Label Progress_warning;
    }
}