from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from core.models import BlogPost, Project


class GenerateSampleDataCommandTests(TestCase):
    """Tests for the generate_sample_data management command."""

    def call_command(self, *args, **kwargs):
        """Helper to call command and capture output."""
        out = StringIO()
        call_command(
            "generate_sample_data",
            *args,
            stdout=out,
            stderr=StringIO(),
            **kwargs,
        )
        return out.getvalue()

    def test_command_creates_default_number_of_objects(self):
        """Test that command creates default number of blog posts and projects."""
        initial_posts = BlogPost.objects.count()
        initial_projects = Project.objects.count()

        output = self.call_command()

        final_posts = BlogPost.objects.count()
        final_projects = Project.objects.count()

        self.assertEqual(final_posts - initial_posts, 10)
        self.assertEqual(final_projects - initial_projects, 5)
        self.assertIn("Created 10 blog posts", output)
        self.assertIn("Created 5 projects", output)

    def test_command_with_custom_counts(self):
        """Test command with custom counts for posts and projects."""
        initial_posts = BlogPost.objects.count()
        initial_projects = Project.objects.count()

        output = self.call_command("--posts=3", "--projects=2")

        final_posts = BlogPost.objects.count()
        final_projects = Project.objects.count()

        self.assertEqual(final_posts - initial_posts, 3)
        self.assertEqual(final_projects - initial_projects, 2)
        self.assertIn("Created 3 blog posts", output)
        self.assertIn("Created 2 projects", output)

    def test_command_with_clear_flag(self):
        """Test that --clear flag removes existing data."""
        # Create initial data
        BlogPost.objects.create(
            title="Test Post", content="Test content", slug="test-post"
        )
        Project.objects.create(
            title="Test Project", description="Test description", slug="test-project"
        )

        initial_posts = BlogPost.objects.count()
        initial_projects = Project.objects.count()

        self.assertEqual(initial_posts, 1)
        self.assertEqual(initial_projects, 1)

        # Run command with --clear flag
        output = self.call_command("--posts=2", "--projects=1", "--clear")

        final_posts = BlogPost.objects.count()
        final_projects = Project.objects.count()

        self.assertEqual(final_posts, 2)
        self.assertEqual(final_projects, 1)
        self.assertIn("Existing data cleared", output)

    def test_blog_posts_have_required_fields(self):
        """Test that generated blog posts have all required fields populated."""
        self.call_command("--posts=1", "--projects=0")

        blog_post = BlogPost.objects.first()
        self.assertIsNotNone(blog_post)
        self.assertTrue(blog_post.title)
        self.assertTrue(blog_post.slug)
        self.assertTrue(blog_post.content)
        self.assertTrue(blog_post.excerpt)
        self.assertIsNotNone(blog_post.published)
        self.assertIsNotNone(blog_post.created_at)

    def test_projects_have_required_fields(self):
        """Test that generated projects have all required fields populated."""
        self.call_command("--posts=0", "--projects=1")

        project = Project.objects.first()
        self.assertIsNotNone(project)
        self.assertTrue(project.title)
        self.assertTrue(project.slug)
        self.assertTrue(project.description)
        self.assertTrue(project.tech_stack)
        self.assertIsNotNone(project.featured)
        self.assertIsNotNone(project.created_at)

    def test_published_posts_have_published_at_date(self):
        """Test that published blog posts have a published_at date set."""
        self.call_command("--posts=20", "--projects=0")

        published_posts = BlogPost.objects.filter(published=True)
        for post in published_posts:
            self.assertIsNotNone(post.published_at)

    def test_slugs_are_unique(self):
        """Test that generated slugs are unique for each model."""
        self.call_command("--posts=5", "--projects=5")

        blog_slugs = list(BlogPost.objects.values_list("slug", flat=True))
        self.assertEqual(len(blog_slugs), len(set(blog_slugs)))

        project_slugs = list(Project.objects.values_list("slug", flat=True))
        self.assertEqual(len(project_slugs), len(set(project_slugs)))

    def test_duplicate_titles_get_unique_slugs(self):
        """Test that models with duplicate titles get unique slugs."""
        # Create blog posts with the same title
        post1 = BlogPost.objects.create(
            title="Test Post", content="Test content 1"
        )
        post2 = BlogPost.objects.create(
            title="Test Post", content="Test content 2"
        )
        post3 = BlogPost.objects.create(
            title="Test Post", content="Test content 3"
        )

        self.assertEqual(post1.slug, "test-post")
        self.assertEqual(post2.slug, "test-post-1")
        self.assertEqual(post3.slug, "test-post-2")

        # Create projects with the same title
        proj1 = Project.objects.create(
            title="Test Project", description="Test description 1"
        )
        proj2 = Project.objects.create(
            title="Test Project", description="Test description 2"
        )

        self.assertEqual(proj1.slug, "test-project")
        self.assertEqual(proj2.slug, "test-project-1")
