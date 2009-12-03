
;;;; -*-Emacs-Lisp-*- More Descriptive Names for Backup and Auto-Save Files
;;;; Written by Eric Eide, last modified on 1994/12/22 21:45:37.
;;;; (C) Copyright 1991, 1994, Eric Eide and the University of Utah
;;;;
;;;; COPYRIGHT NOTICE
;;;;
;;;; This program is free software; you can redistribute it and/or modify it
;;;; under the terms of the GNU General Public License as published by the Free
;;;; Software Foundation; either version 2 of the License, or (at your option)
;;;; any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;;;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;;;; for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License along
;;;; with GNU Emacs.  If you did not, write to the Free Software Foundation,
;;;; Inc., 675 Mass Ave., Cambridge, MA 02139, USA.

;;;; AUTHOR
;;;;
;;;; This file was written by Eric Eide (eeide@cs.utah.edu).  The functions in
;;;; this file are largely based on the corresponding functions in the standard
;;;; GNU Emacs distributions (GNU Emacs 18, FSF GNU Emacs 19, Lucid GNU Emacs,
;;;; and XEmacs).
;;;;
;;;;   Eric Eide (eeide@cs.utah.edu)
;;;;   University of Utah
;;;;   3190 Merrill Engineering Building
;;;;   Salt Lake City, Utah  84112

;;;; LISP CODE DIRECTORY INFORMATION
;;;;
;;;; LCD Archive Entry:
;;;; backup|Eric Eide|eeide@cs.utah.edu|
;;;; More descriptive names for backup and auto-save files|
;;;; 1994/12/22 21:45:37|1.4||

;;;; SUMMARY
;;;;
;;;; The functions in this file allow GNU Emacs to use more descriptive names
;;;; for its backup and auto-save files.  GNU Emacs usually uses the following
;;;; name formats:
;;;;
;;;;   <filename>~            for single backups of <filename>.
;;;;   <filename>.~<number>~  for numbered backups of <filename>.
;;;;   ~/%backup%~            when the normal backup cannot be created.
;;;;   #<filename>#           for auto-save files of <filename>.
;;;;   #%<buffer-name>#       for auto-save of buffer <buffer-name> (Emacs 18).
;;;;   #<buffer-name>#<pid>#    ... (FSF's GNU Emacs 19).
;;;;   #<buffer-name>#          ... (Lucid GNU Emacs and XEmacs).
;;;;
;;;; In the University of Utah Department of Computer Science, GNU Emacs has
;;;; been modified to use slightly different names for single backups and
;;;; auto-save files.  Single backups are named ".~<filename>" and auto-save
;;;; files are named ".#<filename>#" or ".#%<buffer-name>#" (in FSF GNU Emacs
;;;; 19, ".#<buffer-name>#<pid>#"), in order to make these files "invisible" on
;;;; UNIX systems.
;;;;
;;;; The functions in this file replace some of the standard functions from
;;;; "files.el", Dired (or Sebastian Kremer's Tree Dired), and Emacs 19's
;;;; "diff.el" in order to allow GNU Emacs use the following, more descriptive
;;;; name formats:
;;;;
;;;;   .backup-<filename>          for single backups of <filename>.
;;;;   .backup<number>-<filename>  for numbered backups of <filename>.
;;;;   ~/.%backup%                 when the normal backup cannot be created.
;;;;   .autosave-<filename>        for auto-save files of <filename>.
;;;;   .autosave%-<buffer-name>    for auto-save files of buffer <buffer-name>.
;;;;                               In <buffer-name>, slashes and NULs are
;;;;                               translated into exclamation points (`!').
;;;;
;;;; These names may be too long for some UNIX systems to handle.  Too bad.
;;;;
;;;; In addition to being more descriptive, these names have an additional
;;;; benefit within the University of Utah's Department of Computer Science.
;;;; Every night, a "sweeper" goes through most every machine's filesystems,
;;;; deleting files that appear to be GNU Emacs backups and auto-saves.  The
;;;; sweeper is intended to free up extra disk space, but it also makes one's
;;;; backup files short-lived.  The only way to avoid the sweeper is to change
;;;; the names of one's backups and auto-saves, which this file does.
;;;;
;;;; As mentioned above, THIS FILE REPLACES SOME OF THE STANDARD FUNCTIONS from
;;;; GNU Emacs' "files.el", Dired (or Sebastain Kremer's Tree Dired), and Emacs
;;;; 19's "diff.el".
;;;;
;;;; The functions in this file are designed to be compatible with most of the
;;;; "current" versions of GNU Emacs, including GNU Emacs 18 (18.55+), Epoch,
;;;; FSF GNU Emacs 19 (19.23+), Lucid GNU Emacs (19.10+), and XEmacs (19.11+).

;;;; YOUR .EMACS FILE
;;;;
;;;; You should load this file from within your own ".emacs" file:
;;;;
;;;;   (load "backup")
;;;;
;;;; DO NOT load Dired (or Sebastian Kremer's Tree Dired) or "diff" after you
;;;; have loaded "backup"!  "backup" redefines a few functions from those other
;;;; packages.  If you load Dired or "diff" after "backup", then the special
;;;; "backup.el" versions of those functions will be lost.
;;;;
;;;; To customize how GNU Emacs handles backup and auto-save files, refer to
;;;; Sections 15.3 and 15.5 of the _GNU_Emacs_Manual_.

;; Make sure that Dired (or Sebastian Kremer's Tree Dired) and "diff.el" are
;; loaded now, because this file replaces a few of their functions.

(require 'dired)
;; FSF GNU Emacs 19 puts the functions that we want to redefine into a separate
;; file "dired-aux" that does not provide itself (so we can't use `require').
(load "dired-aux" t t)

(condition-case nil
    ;; "diff.el" is new with GNU Emacs 19 (both FSF and Lucid).  If we can't
    ;; load it, don't worry; we must be in GNU Emacs 18 or Epoch.
    (require 'diff)
  (error nil))

;; (provide 'backup) at the end of this file.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; The following functions replace their counterparts in "files.el."
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; This is the FSF GNU Emacs 19.25 version of `backup-buffer', modified to be
;;; compatible with GNU Emacs 18.  (The v18 and v19 versions of this function
;;; aren't really that different.)
;;;

(defun backup-buffer ()
  "Make a backup of the disk file visited by the current buffer, if appropriate.
This is normally done before saving the buffer the first time.  If the value is
non-nil, it is the result of `file-modes' on the original file; this means that
the caller, after saving the buffer, should change the modes of the new file to
agree with the old modes."
  (if (and make-backup-files
	   (or ;; `backup-inhibited' is a v19ism.
	       (not (boundp 'backup-inhibited))
	       (not backup-inhibited))
	   (not buffer-backed-up)
	   (file-exists-p buffer-file-name)
	   (memq (aref (elt (file-attributes buffer-file-name) 8) 0)
		 '(?- ?l))
	   )
      (let* ((real-file-name (if (fboundp 'file-chase-links)
				 ;; The v19 way.  If the file name refers to a
				 ;; symbolic link, chase it to the target.
				 ;; Thus we make backups where the real file
				 ;; is.
				 (file-chase-links buffer-file-name)
			       ;; The v18 way.
			       buffer-file-name))
	     (backup-info    (find-backup-file-name real-file-name))
	     (backupname     (car backup-info))
	     (targets        (cdr backup-info))
	     setmodes)
	;; (if (file-directory-p buffer-file-name)
	;;     (error "Cannot save buffer in directory %s" buffer-file-name))
	(condition-case ()
	    (let* ((delete-excess (if (boundp 'delete-old-versions)
				      ;; `delete-old-versions' is the new name
				      ;; of `trim-versions-without-asking' as
				      ;; of the FSF's GNU Emacs 19.26.
				      delete-old-versions
				    trim-versions-without-asking))
		   (delete-old-versions
		    ;; If we have old versions that we may want to delete, ask
		    ;; the user to confirm now.  But don't actually delete
		    ;; until later.
		    (and targets
			 (or (eq delete-excess t)
			     ;; NOTE that we interpret `delete-excess'
			     ;; (a.k.a. the user options `delete-old-versions'
			     ;; or `trim-versions-without-asking') in the v19
			     ;; way: non-nil non-t values mean "never trim,
			     ;; don't ask."
			     (eq delete-excess nil))
			 (or delete-excess
			     (y-or-n-p (format
					"Delete excess backup versions of %s? "
					real-file-name)))
			 )))
	      ;; Actually write the backup file.
	      (condition-case ()
		  (if (or file-precious-flag
			  ;; When running Emacs 18, `real-file-name' may be a
			  ;; symlink at this point.
			  (file-symlink-p real-file-name)
			  backup-by-copying
			  (and backup-by-copying-when-linked
			       (> (file-nlinks real-file-name) 1))
			  (and backup-by-copying-when-mismatch
			       (let ((attr (file-attributes real-file-name)))
				 (or (nth 9 attr)
				     (/= (nth 2 attr) (user-uid)))
				 ))
			  )
		      (condition-case ()
			  (copy-file real-file-name backupname t t)
			(file-error
			 ;; If copying fails because file BACKUPNAME
			 ;; is not writable, delete that file and try again.
			 (if (and (file-exists-p backupname)
				  (not (file-writable-p backupname)))
			     (delete-file backupname))
			 (copy-file real-file-name backupname t t)))
		    ;; `rename-file' should delete old backup.
		    (rename-file real-file-name backupname t)
		    (setq setmodes (file-modes backupname)))
		
		(file-error
		 ;; If trouble writing the backup, write it in ~.
		 (setq backupname (expand-file-name "~/.%backup%"))
		 (message
		  "Cannot write backup file; backing up in ~/.%%backup%%")
		 (sleep-for 1)
		 (condition-case ()
		     (copy-file real-file-name backupname t t)
		   (file-error
		    ;; If copying fails because file BACKUPNAME
		    ;; is not writable, delete that file and try again.
		    (if (and (file-exists-p backupname)
			     (not (file-writable-p backupname)))
			(delete-file backupname))
		    (copy-file real-file-name backupname t t)))))
	      
	      (setq buffer-backed-up t)
	      
	      ;; Now delete the old versions, if desired.
	      (if delete-old-versions
		  (while targets
		    (condition-case ()
			(delete-file (car targets))
		      (file-error nil))
		    (setq targets (cdr targets))))
	      setmodes)
	  (file-error nil))
	)))

;;;
;;; NOTE: GNU Emacs 19 added the second optional argument.
;;;

(defun file-name-sans-versions (name &optional keep-backup-version)
  "Return FILENAME sans backup versions or strings.
This is a separate procedure so your site-init or startup file can redefine it.
If the optional argument KEEP-BACKUP-VERSION is non-nil, we do not remove
backup version numbers, only true file version numbers."
  (let ((handler (and ;; `find-file-name-handler' is a v19ism.
		      (fboundp 'find-file-name-handler)
		      (find-file-name-handler name 'file-name-sans-versions)))
	nondir-name)
    (cond (handler
	   (funcall handler 'file-name-sans-versions name keep-backup-version))
	  
	  ((eq system-type 'vax-vms)
	   ;; ENE: I haven't touched this code for VMS (from FSF GNU Emacs
	   ;; 19.25).
	   ;;
	   ;; VMS version number is (a) semicolon, optional sign, zero or more
	   ;; digits or (b) period, option sign, zero or more digits, provided
	   ;; this is the second period encountered outside of the
	   ;; device/directory part of the file name.
	   (substring name
		      0
		      (or (string-match ";[-+]?[0-9]*\\'" name)
			  (if (string-match "\\.[^]>:]*\\(\\.[-+]?[0-9]*\\)\\'"
					    name)
			      (match-beginning 1))
			  (length name))))
	  
	  (keep-backup-version
	   name)
	  
	  ((string-match "\\`\\.backup[0-9]*-"
			 (setq nondir-name (file-name-nondirectory name)))
	   (concat (file-name-directory name)
		   (substring nondir-name (match-end 0))))
	  
	  (t
	   name))
    ))

;;;
;;;
;;;

(defun make-backup-file-name (file)
  "Create the non-numeric backup file name for FILE.
This is a separate function so you can redefine it for customization."
  (if (eq system-type 'ms-dos)
      ;; ENE: I haven't touched this code for MS-DOS (from FSF GNU Emacs
      ;; 19.25).
      (let ((fn (file-name-nondirectory file)))
	(concat (file-name-directory file)
		(if (string-match "\\([^.]*\\)\\(\\..*\\)?" fn)
		    (substring fn 0 (match-end 1)))
		".bak"))
    (concat (file-name-directory file)
	    ".backup-" (file-name-nondirectory file))))

;;;
;;;
;;;

(defun backup-file-name-p (file)
  "Return non-nil if FILE is a backup file name (numeric or not).
This is a separate function so you can redefine it for customization.  You may
need to redefine `file-name-sans-versions' as well."
  (if (eq system-type 'ms-dos)
      ;; ENE: I haven't touched this code for MS-DOS (from FSF GNU Emacs
      ;; 19.25).
      (string-match "\\.bak\\'" file)
    (let ((nondir-name (file-name-nondirectory file)))
      (or (string-match "\\`\\.backup[0-9]*-" nondir-name)
	  (string-equal ".%backup%" nondir-name))
      )))

;;;
;;;
;;;

(defun find-backup-file-name (fn)
  "Find a file name for a backup file, and suggestions for deletions.
Value is a list whose car is the name for the backup file and whose cdr is a
list of old versions to consider deleting now."
  (if (eq version-control 'never)
      (list (make-backup-file-name fn))
    (let* ((versions (find-backup-versions fn))
	   (high-water-mark (apply 'max 0 versions))
	   (deserve-versions-p (or version-control
				   (> high-water-mark 0)))
	   (number-to-delete (- (length versions)
				;; -1 compensates for the backup we are about
				;; to make.
				kept-old-versions kept-new-versions -1))
	   (fn-directory (file-name-directory fn))
	   (fn-nondirectory (file-name-nondirectory fn)))
      (if (not deserve-versions-p)
	  (list (make-backup-file-name fn))
	(cons (concat fn-directory
		      ".backup" (int-to-string (1+ high-water-mark)) "-"
		      fn-nondirectory)
	      (if (and (> number-to-delete 0)
		       ;; NOTE that the in the standard 18.58 version of this
		       ;; function, the following check uses > instead of >=,
		       ;; which is apparently a mistake.  (The test below is
		       ;; supposed to check for overflow in the computation of
		       ;; the variable `number-to-delete'.)
		       (>= (+ kept-new-versions kept-old-versions -1) 0))
		  (mapcar (function (lambda (n)
				      (concat fn-directory
					      ".backup" (int-to-string n) "-"
					      fn-nondirectory)))
			  (let ((v (nthcdr kept-old-versions versions)))
			    (rplacd (nthcdr (1- number-to-delete) v) ())
			    v))
		nil))))))

;;;
;;; The following function is new, not a replacement for an existing function
;;; in "files.el."
;;;

(defun find-backup-versions (file-name)
  "For FILE-NAME, return a list of the versions of FILE-NAME's backup files.
This list of integers is sorted in increasing numerical order (oldest versions
to newest versions).  If there are no numeric backups of FILE-NAME, return
nil."
  (let ((backups (condition-case nil
		     (file-name-all-completions ".backup"
						(or (file-name-directory
						     file-name)
						    "."))
		   (file-error nil)))
	(backup-file-name-regexp (concat "\\`\\.backup\\([0-9]+\\)-"
					 (regexp-quote
					  (file-name-nondirectory file-name))
					 "\\'"))
	(versions nil))
    (while backups
      (if (string-match backup-file-name-regexp (car backups))
	  (setq versions (cons (string-to-int (substring (car backups)
							 (match-beginning 1)
							 (match-end 1)))
			       versions)))
      (setq backups (cdr backups)))
    (sort versions (function <))))

;;;
;;; The following function is also new, not a replacement for an existing
;;; function in "files.el".
;;;

(defun find-latest-backup-version (file-name)
  "For FILE-NAME, return the version of the file's most recent numeric backup.
If the file has no numeric backup files, return nil."
  (let ((versions (find-backup-versions file-name)))
    (if versions
	(let ((v versions))
	  (while (cdr v)
	    (setq v (cdr v)))
	  (car v))
      nil)))

;;;
;;; NOTE that `backup-extract-version' is no longer used by any of the
;;; functions in this file.  It may be used in other GNU Emacs packages,
;;; however, so it must be redefined.
;;;

(defun backup-extract-version (file-name)
  "Given the name of a numeric backup file, return the backup number."
  (let ((nondir-name (file-name-nondirectory file-name)))
    (if (string-match "\\`\\.backup\\([0-9]+\\)-" nondir-name)
	(string-to-int (substring nondir-name
				  (match-beginning 1) (match-end 1)))
      0)))

;;;
;;;
;;;

(defun make-auto-save-file-name ()
  "Return file name to use for auto-saves of current buffer.
Does not consider `auto-save-visited-file-name' as that variable is checked
before calling this function.  You can redefine this for customization.  See
also `auto-save-file-name-p'."
  (if buffer-file-name
      (concat (file-name-directory buffer-file-name)
	      ".autosave-"
	      (file-name-nondirectory buffer-file-name))
    (let ((name (concat ".autosave%-" (buffer-name))))
      ;; FSF GNU Emacs 19 puts the Emacs pid into the auto-save file name, but
      ;; that loses when one wants to recover the auto-save file from another
      ;; Emacs process.  Say that you're writing in the *mail* buffer when
      ;; Emacs crashes.  The (sensible) code in "sendmail.el" calls `make-auto-
      ;; save-file-name' to determine whether there is unsent, auto-saved mail
      ;; to recover.  If that mail came from a previous Emacs process (far and
      ;; away the most likely case) then this can never succeed as the new
      ;; Emacs pid differs.  (Thanks to Jamie Zawinski for pointing this out in
      ;; the comments for Lucid Emacs' version of this function.)
      ;;
      ;; Destructively translate `/' and `\000' into `!' so that buffers with
      ;; `/' and `\000' in their names can be auto-saved.  (Another idea stolen
      ;; from Lucid's version of this function.)  NOTE that this means that the
      ;; buffer-name to auto-save-file-name mapping is no longer one-to-one;
      ;; the buffers "foo/bar" and "foo!bar" with the same `default-directory'
      ;; will use the same auto-save file.  This situation is rare enough to be
      ;; safely ignored for now.
      (let ((length (length name))
	    (index 0)
	    index-char)
	(while (< index length)
	  (setq index-char (aref name index))
	  (if (or (char-equal index-char ?/)
		  (char-equal index-char ?\000))
	      (aset name index ?\!))
	  (setq index (+ 1 index)))
	;; Return the expanded name (i.e., with directory components).
	(expand-file-name name)
	))
    ))

;;;
;;;
;;;

(defun auto-save-file-name-p (filename)
  "Return non-nil if FILENAME can be yielded by `make-auto-save-file-name'.
FILENAME should lack slashes.  You can redefine this for customization."
  ;; This version handles the slashified cases, too.
  (string-match "\\`\\.autosave%?-" (file-name-nondirectory filename)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; The following functions replace their counterparts in the various Dired
;;;; packages.
;;;;
;;;; NOTE that although the FSF GNU Emacs 19's Dired is based on Sebastian
;;;; Kremer's Tree Dired, the FSF's version has been substantially hacked.
;;;; Lucid GNU Emacs and XEmacs, on the other hand, use an essentially
;;;; unmodified version of Tree Dired.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; The GNU Emacs 18 Dired replacements...
;;;

(defun v18-dired-collect-file-versions (ignore fn)
  "If it looks like fn has versions, we make a list of the versions.
We may want to flag some for deletion."
  (let ((versions (find-backup-versions fn)))
    (if versions
	(setq file-version-assoc-list (cons (cons fn versions)
					    file-version-assoc-list))
      nil)))

;;;
;;;
;;;

(defun v18-dired-trample-file-versions (short-fn long-fn)
  (let* ((looks-like-backup (string-match "\\`\\.backup\\([0-9]+\\)-"
					  short-fn))
	 base-version-list)
    (and looks-like-backup
	 ;; ...and this file appears to be a numbered backup for some existing
	 ;; file...
	 (setq base-version-list
	       (assoc (concat (file-name-directory long-fn)
			      (substring short-fn (match-end 0)))
		      file-version-assoc-list))
	 ;; ...and this version is not to be saved...
	 (not (memq (string-to-int (substring short-fn
					      (match-beginning 1)
					      (match-end 1)))
		    base-version-list))
	 ;; ...then flag this file for death!
	 (dired-flag-this-line-for-DEATH))))

;;;
;;; The FSF GNU Emacs 19 Dired replacements...
;;;
;;; Argh!  The FSF rewrote `dired-flag-{auto-save,backup}-files' so that those
;;; functions would run faster, but now those functions assume that they know
;;; what auto-save and backup files look like.  Fooey.  I "borrowed" the
;;; original Tree Dired functions back.
;;;

(defun v19-dired-collect-file-versions (fn)
  "If it looks like fn has versions, we make a list of the versions.
We may want to flag some for deletion."
  (let ((versions (find-backup-versions fn)))
    (if versions
	(setq dired-file-version-alist (cons (cons fn versions)
					     dired-file-version-alist))
      nil)))

;;;
;;;
;;;

(defun v19-dired-trample-file-versions (fn)
  (let* ((short-fn (file-name-nondirectory fn))
	 (looks-like-backup (string-match "\\`\\.backup\\([0-9]+\\)-"
					  short-fn))
	 base-version-list)
    (and looks-like-backup
	 ;; ...and this file appears to be a numbered backup for some existing
	 ;; file...
	 (setq base-version-list
	       (assoc (concat (file-name-directory fn)
			      (substring short-fn (match-end 0)))
		      dired-file-version-alist))
	 ;; ...and this version is not to be saved...
	 (not (memq (string-to-int (substring short-fn
					      (match-beginning 1)
					      (match-end 1)))
		    base-version-list))
	 ;; ...then flag this file for deletion.
	 (progn (beginning-of-line)
		(delete-char 1)
		(insert dired-del-marker)))))

;;;
;;;
;;;

(defun v19-dired-flag-auto-save-files (&optional unflag-p)
  "Flag for deletion files whose names suggest they are auto save files.
A prefix argument says to unflag those files instead."
  (interactive "P")
  ;; (dired-check-ls-l) is undefined in FSF GNU Emacs v19 Dired.
  (let ((dired-marker-char (if unflag-p ?\040 dired-del-marker)))
    (dired-mark-if
       (and (not (looking-at dired-re-dir))
	    (let ((fn (dired-get-filename t t)))
	      (if fn (auto-save-file-name-p
		      (file-name-nondirectory fn)))))
       "auto-save file")))

;;;
;;;
;;;

(defun v19-dired-flag-backup-files (&optional unflag-p)
  "Flag all backup files for deletion.
With prefix argument, unflag these files."
  (interactive "P")
  ;; (dired-check-ls-l) is undefined in FSF GNU Emacs v19 Dired.
  (let ((dired-marker-char (if unflag-p ?\040 dired-del-marker)))
    (dired-mark-if
     (and (not (looking-at dired-re-dir))
	  (let ((fn (dired-get-filename t t)))
	    (if fn (backup-file-name-p fn))))
     "backup file")))

;;;
;;; The Tree Dired replacements...
;;;

(defun tree-dired-collect-file-versions (fn)
  "If it looks like fn has versions, we make a list of the versions.
We may want to flag some for deletion."
  (let ((versions (find-backup-versions fn)))
    (if versions
	(setq file-version-assoc-list (cons (cons fn versions)
					    file-version-assoc-list))
      nil)))

;;;
;;;
;;;

(defun tree-dired-trample-file-versions (fn)
  (let* ((short-fn (file-name-nondirectory fn))
	 (looks-like-backup (string-match "\\`\\.backup\\([0-9]+\\)-"
					  short-fn))
	 base-version-list)
    (and looks-like-backup
	 ;; ...and this file appears to be a numbered backup for some existing
	 ;; file...
	 (setq base-version-list
	       (assoc (concat (file-name-directory fn)
			      (substring short-fn (match-end 0)))
		      file-version-assoc-list))
	 ;; ...and this version is not to be saved...
	 (not (memq (string-to-int (substring short-fn
					      (match-beginning 1)
					      (match-end 1)))
		    base-version-list))
	 ;; ...then flag this file for deletion.
	 (progn (beginning-of-line)
		(delete-char 1)
		(insert dired-del-marker)))))

;;;
;;;
;;;

(defun tree-dired-latest-backup-file (fn)
  "Return the latest existing backup of FILE, or nil."
  ;; First try simple backup, then the highest numbered of the numbered
  ;; backups.
  ;;
  ;; Ignore the value of `version-control' because we look for existing
  ;; backups, which maybe were made earlier or by another user with a different
  ;; value of `version-control'.
  (setq fn (expand-file-name fn))
  (let ((backup-name (make-backup-file-name fn)))
    (if (file-exists-p backup-name)
	backup-name
      (let ((latest-version (find-latest-backup-version fn)))
	(if latest-version
	    (concat (file-name-directory fn)
		    ".backup" (int-to-string latest-version) "-"
		    (file-name-nondirectory fn))
	  nil)))
    ))

;;;
;;; Determine which version of Dired we're using, and then do the appropriate
;;; function overloading.
;;;

(cond ((boundp 'dired-version)
       ;; We're using Tree Dired.  Note that Lucid GNU Emacs and XEmacs come
       ;; with Tree Dired.
       (fset 'dired-collect-file-versions
	     (symbol-function 'tree-dired-collect-file-versions))
       (fset 'dired-trample-file-versions
	     (symbol-function 'tree-dired-trample-file-versions))
       (fset 'latest-backup-file
	     (symbol-function 'tree-dired-latest-backup-file))
       )
      
      ((boundp 'dired-marker-char)
       ;; We're using the hacked-up version of Tree Dired that is part of the
       ;; FSF's GNU Emacs 19.  All Tree Dired-based Dired modes define the
       ;; `dired-marker-char' variable, but only the FSF's version fails to
       ;; define `dired-version' (which was checked above).
       (fset 'dired-collect-file-versions
	     (symbol-function 'v19-dired-collect-file-versions))
       (fset 'dired-trample-file-versions
	     (symbol-function 'v19-dired-trample-file-versions))
       (fset 'dired-flag-auto-save-files
	     (symbol-function 'v19-dired-flag-auto-save-files))
       (fset 'dired-flag-backup-files
	     (symbol-function 'v19-dired-flag-backup-files))
       )
      
      (t
       ;; We're using the Dired that comes with GNU Emacs 18.
       (fset 'dired-collect-file-versions
	     (symbol-function 'v18-dired-collect-file-versions))
       (fset 'dired-trample-file-versions
	     (symbol-function 'v18-dired-trample-file-versions))
       ))

;;;
;;; Finally, forget about the function bindings we no longer need, so they
;;; won't confuse anybody later on.
;;;

(fmakunbound 'v18-dired-collect-file-versions)
(fmakunbound 'v18-dired-trample-file-versions)
(fmakunbound 'v19-dired-collect-file-versions)
(fmakunbound 'v19-dired-trample-file-versions)
(fmakunbound 'v19-dired-flag-auto-save-files)
(fmakunbound 'v19-dired-flag-backup-files)
(fmakunbound 'tree-dired-collect-file-versions)
(fmakunbound 'tree-dired-trample-file-versions)
(fmakunbound 'tree-dired-latest-backup-file)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; The following functions replace their counterparts in the "diff.el"
;;;; packages that come with FSF GNU Emacs 19, Lucid GNU Emacs, and XEmacs.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; This is the FSF GNU Emacs 19.25 version of `diff-latest-backup-file',
;;; modified as necessary to handle our improved backup file names.  NOTE that
;;; this function is almost identical to `tree-dired-latest-backup-file',
;;; above.
;;;

(defun v19-diff-latest-backup-file (fn)
  "Return the latest existing backup of FILE, or nil."
  (let ((handler (find-file-name-handler fn 'diff-latest-backup-file)))
    (if handler
	(funcall handler 'diff-latest-backup-file fn)
      ;; First try simple backup, then the highest numbered of the numbered
      ;; backups.
      ;;
      ;; Ignore the value of `version-control' because we look for existing
      ;; backups, which maybe were made earlier or by another user with a
      ;; different value of `version-control'.
      (setq fn (file-chase-links (expand-file-name fn)))
      (let ((backup-name (make-backup-file-name fn)))
	 (if (file-exists-p backup-name)
	     backup-name
	   (let ((latest-version (find-latest-backup-version fn)))
	     (if latest-version
		 (concat (file-name-directory fn)
			 ".backup" (int-to-string latest-version) "-"
			 (file-name-nondirectory fn))
	       nil)))
	 ))
    ))

;;;
;;; Overload as necessary.
;;;

(if (fboundp 'diff-latest-backup-file)
    (fset 'diff-latest-backup-file
	  (symbol-function 'v19-diff-latest-backup-file)))

;;;
;;; Finally, forget about the function bindings we no longer need, so they
;;; won't confuse anybody later on.
;;;

(fmakunbound 'v19-diff-latest-backup-file)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; Finally, here is the `provide' statement.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'backup)

;; End of file.

