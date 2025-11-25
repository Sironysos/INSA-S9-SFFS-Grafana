-- Create the test database (run as a superuser or a user that can create DBs)
\connect db;

-- Schema: users, posts, comments
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT,
    published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Sample test data: users
INSERT INTO users (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob',   'bob@example.com'),
    ('Carol', 'carol@example.com'),
    ('Dave',  'dave@example.com'),
    ('Eve',   'eve@example.com');

-- Sample test data: posts
INSERT INTO posts (user_id, title, body, published) VALUES
    (1, 'Welcome to the blog', 'Hello world! This is Alice.', true),
    (2, 'Bob''s Thoughts', 'Short post by Bob.', true),
    (1, 'Draft: Project Ideas', 'Notes and ideas (private).', false),
    (3, 'Carol''s Tips', 'Useful tips and tricks.', true),
    (4, 'Announcement', 'Important announcement from Dave.', true),
    (5, 'Eve''s Diary', 'Personal diary entry (private).', false);

-- Sample test data: comments
INSERT INTO comments (post_id, user_id, content) VALUES
    (1, 2, 'Nice post, Alice!'),
    (1, 3, 'Welcome aboard!'),
    (2, 1, 'Good perspective, Bob.'),
    (4, 5, 'Thanks for the tips, Carol.'),
    (5, 1, 'Keeping it private is fine.');

-- Useful indexes
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_comments_post_id ON comments(post_id);