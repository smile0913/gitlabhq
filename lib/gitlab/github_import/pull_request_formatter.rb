module Gitlab
  module GithubImport
    class PullRequestFormatter < BaseFormatter
      def attributes
        {
          iid: number,
          title: raw_data.title,
          description: description,
          source_project: source_project,
          source_branch: source_branch,
          head_source_sha: source_sha,
          target_project: target_project,
          target_branch: target_branch,
          base_target_sha: target_sha,
          state: state,
          milestone: milestone,
          author_id: author_id,
          assignee_id: assignee_id,
          created_at: raw_data.created_at,
          updated_at: updated_at
        }
      end

      def number
        raw_data.number
      end

      def valid?
        !cross_project?
      end

      def source_branch_exists?
        source_project.repository.branch_exists?(source_ref)
      end

      def source_branch
        @source_branch ||= if source_branch_exists?
                             source_ref
                           else
                             "#{source_ref}-#{short_id(source_sha)}"
                           end
      end

      def short_id(sha, length = 7)
        sha.to_s[0..length]
      end

      def source_sha
        raw_data.head.sha
      end

      def target_branch_exists?
        target_project.repository.branch_exists?(target_ref)
      end

      def target_branch
        @target_branch ||= if target_branch_exists?
                             target_ref
                           else
                             "#{target_ref}-#{short_id(target_sha)}"
                           end
      end

      def target_sha
        raw_data.base.sha
      end

      private

      def assigned?
        raw_data.assignee.present?
      end

      def assignee_id
        if assigned?
          gl_user_id(raw_data.assignee.id)
        end
      end

      def author
        raw_data.user.login
      end

      def author_id
        gl_user_id(raw_data.user.id) || project.creator_id
      end

      def body
        raw_data.body || ""
      end

      def cross_project?
        source_repo.present? && target_repo.present? && source_repo.id != target_repo.id
      end

      def description
        formatter.author_line(author) + body
      end

      def milestone
        if raw_data.milestone.present?
          project.milestones.find_by(iid: raw_data.milestone.number)
        end
      end

      def source_project
        project
      end

      def source_repo
        raw_data.head.repo
      end

      def source_ref
        raw_data.head.ref
      end

      def target_project
        project
      end

      def target_repo
        raw_data.base.repo
      end

      def target_ref
        raw_data.base.ref
      end

      def state
        @state ||= case true
                   when raw_data.state == 'closed' && raw_data.merged_at.present?
                     'merged'
                   when raw_data.state == 'closed'
                     'closed'
                   else
                     'opened'
                   end
      end

      def updated_at
        case state
        when 'merged' then raw_data.merged_at
        when 'closed' then raw_data.closed_at
        else
          raw_data.updated_at
        end
      end
    end
  end
end
